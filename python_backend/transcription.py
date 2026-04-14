# python_backend/transcription.py
# Handles audio download + AssemblyAI transcription with speaker diarization

import os
import tempfile
import uuid
from datetime import datetime
from typing import Dict, List, Optional, TypedDict

import assemblyai as aai
import requests
from langgraph.graph import END, START, StateGraph
from urllib.parse import urlparse

ASSEMBLYAI_API_KEY = os.getenv("ASSEMBLYAI_API_KEY")
if not ASSEMBLYAI_API_KEY:
    raise ValueError("ASSEMBLYAI_API_KEY not found in environment variables")


# ── State ─────────────────────────────────────────────────────────────────────

class TranscriptionState(TypedDict):
    session_id: str
    audio_input: Optional[str]
    audio_file_path: Optional[str]
    is_temp_file: bool
    raw_transcript: str
    speaker_segments: List[Dict]
    formatted_transcript: str
    error_message: Optional[str]
    processing_complete: bool


# ── AssemblyAI Transcriber ────────────────────────────────────────────────────

class AssemblyAITranscriber:
    def __init__(self):
        aai.settings.api_key = ASSEMBLYAI_API_KEY
        self.transcriber = aai.Transcriber()

    def transcribe(self, audio_file: str) -> tuple:
        try:
            print("🎵 Starting transcription...")
            config = aai.TranscriptionConfig(
                speaker_labels=True,
                speakers_expected=None,
                auto_chapters=False,
                sentiment_analysis=False,
                auto_highlights=False,
                speech_model=aai.SpeechModel.nano,
            )
            print("⏳ Processing audio...")
            transcript = self.transcriber.transcribe(audio_file, config)

            if transcript.status == aai.TranscriptStatus.error:
                print(f"❌ Transcription failed: {transcript.error}")
                return "", "", []

            full_text = transcript.text
            print("✅ Transcription complete!")

            speaker_segments = []
            formatted = ""

            if transcript.utterances:
                print(f"🎭 Processing {len(transcript.utterances)} utterances...")
                for u in transcript.utterances:
                    speaker_segments.append({
                        "speaker": f"Speaker_{u.speaker}",
                        "text": u.text,
                        "confidence": u.confidence,
                        "start": u.start / 1000,
                        "end": u.end / 1000,
                    })
                    formatted += f"Speaker_{u.speaker}: {u.text}\n\n"

                # Label the most-talking speaker as Lecturer
                word_counts = {}
                for seg in speaker_segments:
                    s = seg["speaker"]
                    word_counts[s] = word_counts.get(s, 0) + len(seg["text"].split())
                lecturer = max(word_counts, key=word_counts.get)
                for seg in speaker_segments:
                    seg["role"] = "Lecturer" if seg["speaker"] == lecturer else "Student"

                unique = len(set(s["speaker"] for s in speaker_segments))
                print(f"🎭 {unique} speaker(s) detected. Lecturer: {lecturer}")
            else:
                print("⚠️ No speaker labels — treating as single speaker")
                speaker_segments = [{
                    "speaker": "Speaker_A",
                    "role": "Lecturer",
                    "text": full_text,
                    "confidence": 0.8,
                    "start": 0,
                    "end": 60,
                }]
                formatted = f"Speaker_A: {full_text}\n\n"

            return full_text, formatted, speaker_segments

        except Exception as e:
            print(f"❌ Transcription error: {e}")
            return "", "", []


# ── Graph Nodes ───────────────────────────────────────────────────────────────

def download_node(state: TranscriptionState) -> TranscriptionState:
    print("\n🌐 AUDIO INPUT PROCESSING")
    audio_input = state.get("audio_input")

    if not audio_input:
        return {**state, "error_message": "No audio input provided", "processing_complete": True}

    if audio_input.startswith(("http://", "https://")):
        print(f"📡 URL: {audio_input}")
        try:
            parsed = urlparse(audio_input)
            response = requests.get(
                audio_input,
                headers={"User-Agent": "Mozilla/5.0"},
                stream=True,
                timeout=60
            )
            response.raise_for_status()

            ext = ".mp3"
            _, url_ext = os.path.splitext(parsed.path)
            if url_ext.lower() in [".mp3", ".wav", ".m4a", ".flac", ".ogg", ".aac"]:
                ext = url_ext

            tmp = tempfile.NamedTemporaryFile(delete=False, suffix=ext)
            size = 0
            for chunk in response.iter_content(8192):
                if chunk:
                    tmp.write(chunk)
                    size += len(chunk)
            tmp.close()

            if size == 0:
                os.unlink(tmp.name)
                raise ValueError("Downloaded file is empty")

            print(f"✅ Downloaded {size/1024/1024:.1f} MB → {tmp.name}")
            return {**state, "audio_file_path": tmp.name, "is_temp_file": True, "error_message": None}

        except Exception as e:
            return {**state, "error_message": f"Download failed: {str(e)}", "processing_complete": True}
    else:
        print(f"📁 Local file: {audio_input}")
        if not os.path.exists(audio_input):
            return {**state, "error_message": f"File not found: {audio_input}", "processing_complete": True}
        print(f"✅ {os.path.getsize(audio_input)/1024/1024:.1f} MB")
        return {**state, "audio_file_path": audio_input, "is_temp_file": False, "error_message": None}


def transcribe_node(state: TranscriptionState) -> TranscriptionState:
    if state.get("error_message"):
        return state

    audio_file = state.get("audio_file_path")
    if not audio_file:
        return {**state, "error_message": "No audio file", "processing_complete": True}

    print("\n🎵 TRANSCRIBING WITH SPEAKER DIARIZATION")
    raw, formatted, segments = AssemblyAITranscriber().transcribe(audio_file)

    if not raw.strip():
        return {**state, "error_message": "No speech detected", "processing_complete": True}

    return {
        **state,
        "raw_transcript": raw,
        "formatted_transcript": formatted,
        "speaker_segments": segments,
        "error_message": None,
    }


def cleanup_node(state: TranscriptionState) -> TranscriptionState:
    if state.get("is_temp_file") and state.get("audio_file_path"):
        try:
            os.unlink(state["audio_file_path"])
            print("\n🧹 Temp file cleaned up")
        except Exception as e:
            print(f"⚠️ Cleanup failed: {e}")
    return {**state, "processing_complete": True}


# ── Graph ─────────────────────────────────────────────────────────────────────

def build_transcription_graph():
    wf = StateGraph(TranscriptionState)
    wf.add_node("download", download_node)
    wf.add_node("transcribe", transcribe_node)
    wf.add_node("cleanup", cleanup_node)
    wf.add_edge(START, "download")
    wf.add_edge("download", "transcribe")
    wf.add_edge("transcribe", "cleanup")
    wf.add_edge("cleanup", END)
    return wf.compile()


# ── Public Interface ──────────────────────────────────────────────────────────

def transcribe_audio(audio_input: str) -> dict:
    """Transcribe audio file or URL. Returns transcript + speaker segments."""
    if not audio_input or not isinstance(audio_input, str):
        return {"success": False, "dev_message": "Invalid input", "user_message": "Please provide a valid audio file.", "payload": {}}

    print(f"\n🚀 Transcribing: {audio_input}")

    initial: TranscriptionState = {
        "session_id": str(uuid.uuid4()),
        "audio_input": audio_input.strip(),
        "audio_file_path": None,
        "is_temp_file": False,
        "raw_transcript": "",
        "speaker_segments": [],
        "formatted_transcript": "",
        "error_message": None,
        "processing_complete": False,
    }

    try:
        final = build_transcription_graph().invoke(initial)

        if final.get("error_message"):
            return {
                "success": False,
                "dev_message": final["error_message"],
                "user_message": "Transcription failed. Please try again.",
                "payload": {},
            }

        speaker_count = len(set(s["speaker"] for s in final.get("speaker_segments", [])))

        return {
            "success": True,
            "dev_message": "Transcription completed",
            "user_message": "Audio transcribed successfully!",
            "payload": {
                "transcript": final.get("formatted_transcript", ""),
                "raw_transcript": final.get("raw_transcript", ""),
                "speaker_segments": final.get("speaker_segments", []),
                "metadata": {
                    "session_id": final["session_id"],
                    "speaker_count": speaker_count,
                    "processing_timestamp": datetime.now().isoformat(),
                    "input_type": "url" if audio_input.startswith(("http", "https")) else "local_file",
                },
            },
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "dev_message": f"Error: {str(e)}",
            "user_message": "An unexpected error occurred.",
            "payload": {},
        }
