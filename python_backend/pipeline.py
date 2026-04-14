N# python_backend/pipeline.py
# Core transcription + summarization pipeline using AssemblyAI + OpenAI + LangGraph

import os
import tempfile
import uuid
from datetime import datetime
from typing import Dict, List, Optional, TypedDict

import assemblyai as aai
import requests
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.graph import END, START, StateGraph
from urllib.parse import urlparse
import mimetypes

# ── Configuration ─────────────────────────────────────────────────────────────

ASSEMBLYAI_API_KEY = os.getenv("ASSEMBLYAI_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

if not ASSEMBLYAI_API_KEY:
    raise ValueError("ASSEMBLYAI_API_KEY not found in environment variables")
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY not found in environment variables")


# ── State ─────────────────────────────────────────────────────────────────────

class TranscriptionState(TypedDict):
    session_id: str
    audio_input: Optional[str]
    audio_file_path: Optional[str]
    is_temp_file: bool
    raw_transcript: str
    speaker_segments: List[Dict]
    final_transcript: str
    title: Optional[str]
    overview: Optional[str]
    key_points: Optional[str]
    action_items: Optional[str]
    important_details: Optional[str]
    error_message: Optional[str]
    processing_complete: bool


# ── AssemblyAI Transcriber ────────────────────────────────────────────────────

class AssemblyAITranscriber:
    def __init__(self):
        aai.settings.api_key = ASSEMBLYAI_API_KEY
        self.transcriber = aai.Transcriber()

    def transcribe_with_speakers(self, audio_file: str) -> tuple:
        try:
            print("🎵 Starting transcription...")
            config = aai.TranscriptionConfig(
                speaker_labels=True,
                speakers_expected=None,
                auto_chapters=False,
                sentiment_analysis=False,
                auto_highlights=False,
            )

            print("⏳ Processing audio... This may take a moment...")
            transcript = self.transcriber.transcribe(audio_file, config)

            if transcript.status == aai.TranscriptStatus.error:
                print(f"❌ Transcription failed: {transcript.error}")
                return "", "", []

            full_text = transcript.text
            print("✅ Transcription completed!")

            speaker_segments = []
            formatted_transcript = ""

            if transcript.utterances:
                print(f"🎭 Processing {len(transcript.utterances)} utterances...")
                for utterance in transcript.utterances:
                    segment = {
                        "speaker": f"Speaker_{utterance.speaker}",
                        "text": utterance.text,
                        "confidence": utterance.confidence,
                        "start": utterance.start / 1000,
                        "end": utterance.end / 1000,
                    }
                    speaker_segments.append(segment)
                    formatted_transcript += f"Speaker_{utterance.speaker}: {utterance.text}\n\n"
            else:
                print("⚠️ No speaker labels detected, treating as single speaker")
                speaker_segments = [{
                    "speaker": "Speaker_A",
                    "text": full_text,
                    "confidence": 0.8,
                    "start": 0,
                    "end": 60,
                }]
                formatted_transcript = f"Speaker_A: {full_text}\n\n"

            unique_speakers = len(set(seg["speaker"] for seg in speaker_segments))
            print(f"🎭 Detected {unique_speakers} unique speaker(s)")
            return full_text, formatted_transcript, speaker_segments

        except Exception as e:
            print(f"❌ Transcription error: {e}")
            return "", "", []


# ── Graph Nodes ───────────────────────────────────────────────────────────────

def download_audio_node(state: TranscriptionState) -> TranscriptionState:
    """Download audio from URL or validate local file path."""
    print("\n🌐 AUDIO INPUT PROCESSING")

    audio_input = state.get("audio_input")
    if not audio_input:
        return {**state, "error_message": "No audio input provided", "processing_complete": True}

    if audio_input.startswith(("http://", "https://")):
        print(f"📡 URL detected: {audio_input}")
        try:
            parsed_url = urlparse(audio_input)
            if not parsed_url.scheme or not parsed_url.netloc:
                raise ValueError("Invalid URL format")

            headers = {"User-Agent": "Mozilla/5.0"}
            response = requests.get(audio_input, headers=headers, stream=True, timeout=60)
            response.raise_for_status()

            file_extension = ".mp3"
            url_path = parsed_url.path
            if url_path:
                _, ext = os.path.splitext(url_path)
                if ext.lower() in [".mp3", ".wav", ".m4a", ".flac", ".ogg", ".wma", ".aac"]:
                    file_extension = ext

            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=file_extension)
            temp_filename = temp_file.name
            total_size = 0

            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    temp_file.write(chunk)
                    total_size += len(chunk)
            temp_file.close()

            if total_size == 0:
                os.unlink(temp_filename)
                raise ValueError("Downloaded file is empty")

            print(f"✅ Downloaded {total_size/1024/1024:.1f} MB → {temp_filename}")
            return {**state, "audio_file_path": temp_filename, "is_temp_file": True, "error_message": None}

        except Exception as e:
            return {**state, "error_message": f"Failed to download audio: {str(e)}", "processing_complete": True}

    else:
        print(f"📁 Local file: {audio_input}")
        if not os.path.exists(audio_input):
            return {**state, "error_message": f"File not found: {audio_input}", "processing_complete": True}
        file_size = os.path.getsize(audio_input)
        print(f"✅ File exists — {file_size/1024/1024:.1f} MB")
        return {**state, "audio_file_path": audio_input, "is_temp_file": False, "error_message": None}


def transcribe_node(state: TranscriptionState) -> TranscriptionState:
    """Transcribe audio with speaker diarization."""
    if state.get("error_message"):
        return state

    audio_file = state.get("audio_file_path")
    if not audio_file:
        return {**state, "error_message": "No audio file for transcription", "processing_complete": True}

    print("\n🎵 TRANSCRIPTION WITH SPEAKER DIARIZATION")
    transcriber = AssemblyAITranscriber()
    raw, formatted, segments = transcriber.transcribe_with_speakers(audio_file)

    if not raw.strip():
        return {**state, "error_message": "No speech detected in audio", "processing_complete": True}

    return {
        **state,
        "raw_transcript": raw,
        "final_transcript": formatted,
        "speaker_segments": segments,
        "error_message": None,
    }


def summarize_node(state: TranscriptionState) -> TranscriptionState:
    """Generate structured summary using GPT-4o-mini."""
    if state.get("error_message"):
        return state

    print("\n🎯 GENERATING STRUCTURED SUMMARY")
    transcript = state.get("final_transcript", "")

    if not transcript.strip():
        return {
            **state,
            "title": "Empty Transcript",
            "overview": "No transcript available.",
            "key_points": "No content to analyze.",
            "action_items": "No action items identified.",
            "important_details": "No details available.",
            "processing_complete": True,
        }

    try:
        llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.3, api_key=OPENAI_API_KEY)

        def ask(system: str, user: str) -> str:
            return llm.invoke([
                SystemMessage(content=system),
                HumanMessage(content=user),
            ]).content.strip()

        title = ask(
            "Return only a short title (max 6 words). No quotes or extra text.",
            f"Generate a title for this conversation:\n\n{transcript[:300]}...",
        ).strip('"').strip("'")

        overview = ask(
            "Return a concise 2-3 sentence overview. Focus on who is speaking, context, and main topic.",
            f"Provide an overview of this conversation:\n\n{transcript}",
        )

        key_points = ask(
            "Return a numbered list of 3-5 key points (1. 2. 3.). Be specific and concise.",
            f"List the most important points from this conversation:\n\n{transcript}",
        )

        action_items = ask(
            "List action items using bullet points (•). If none, return 'No specific action items identified.'",
            f"Identify any action items or next steps from this conversation:\n\n{transcript}",
        )

        important_details = ask(
            "List important names, dates, numbers, or locations using bullet points (•). If none, return 'No specific details to highlight.'",
            f"Extract key details from this conversation:\n\n{transcript}",
        )

        print("✅ Summary generation complete!")
        return {
            **state,
            "title": title,
            "overview": overview,
            "key_points": key_points,
            "action_items": action_items,
            "important_details": important_details,
            "processing_complete": True,
            "error_message": None,
        }

    except Exception as e:
        print(f"❌ Summary error: {e}")
        return {**state, "error_message": f"Summary generation error: {str(e)}", "processing_complete": True}


def cleanup_node(state: TranscriptionState) -> TranscriptionState:
    """Clean up temporary files."""
    if state.get("is_temp_file") and state.get("audio_file_path"):
        try:
            os.unlink(state["audio_file_path"])
            print("\n🧹 Temp file cleaned up")
        except Exception as e:
            print(f"⚠️ Could not clean up temp file: {e}")
    return {**state, "processing_complete": True}


# ── Graph ─────────────────────────────────────────────────────────────────────

def build_graph():
    workflow = StateGraph(TranscriptionState)
    workflow.add_node("download", download_audio_node)
    workflow.add_node("transcribe", transcribe_node)
    workflow.add_node("summarize", summarize_node)
    workflow.add_node("cleanup", cleanup_node)
    workflow.add_edge(START, "download")
    workflow.add_edge("download", "transcribe")
    workflow.add_edge("transcribe", "summarize")
    workflow.add_edge("summarize", "cleanup")
    workflow.add_edge("cleanup", END)
    return workflow.compile()


# ── Public Interface ──────────────────────────────────────────────────────────

def process_audio(audio_input: str) -> dict:
    """Process audio through the full pipeline. Returns structured result dict."""
    if not audio_input or not isinstance(audio_input, str):
        return {
            "success": False,
            "dev_message": "Invalid audio input",
            "user_message": "Please provide a valid audio file path or URL.",
            "payload": {},
        }

    print(f"\n🚀 Starting pipeline for: {audio_input}")

    initial_state: TranscriptionState = {
        "session_id": str(uuid.uuid4()),
        "audio_input": audio_input.strip(),
        "audio_file_path": None,
        "is_temp_file": False,
        "raw_transcript": "",
        "speaker_segments": [],
        "final_transcript": "",
        "title": None,
        "overview": None,
        "key_points": None,
        "action_items": None,
        "important_details": None,
        "error_message": None,
        "processing_complete": False,
    }

    try:
        graph = build_graph()
        final = graph.invoke(initial_state)

        if final.get("error_message"):
            return {
                "success": False,
                "dev_message": final["error_message"],
                "user_message": "Something went wrong during processing. Please try again.",
                "payload": {},
            }

        speaker_count = len(set(s["speaker"] for s in final.get("speaker_segments", [])))

        return {
            "success": True,
            "dev_message": "Pipeline completed successfully",
            "user_message": "Your audio has been processed successfully!",
            "payload": {
                "title": final.get("title", "Audio Summary"),
                "overview": final.get("overview", "No overview available."),
                "key_points": final.get("key_points", "No key points identified."),
                "action_items": final.get("action_items", "No action items identified."),
                "important_details": final.get("important_details", "No important details."),
                "metadata": {
                    "session_id": final.get("session_id"),
                    "speaker_count": speaker_count,
                    "processing_timestamp": datetime.now().isoformat(),
                    "input_type": "url" if audio_input.startswith(("http", "https")) else "local_file",
                    "original_input": audio_input,
                },
            },
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "dev_message": f"Pipeline error: {str(e)}",
            "user_message": "An unexpected error occurred. Please try again.",
            "payload": {},
        }
