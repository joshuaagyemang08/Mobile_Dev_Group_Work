# python_backend/main.py
# FastAPI server — two endpoints: transcription and notes generation

import os
import shutil
import tempfile
from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

from transcription import transcribe_audio
from notes import generate_notes

app = FastAPI(title="Scrib API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request Models ────────────────────────────────────────────────────────────

class NotesRequest(BaseModel):
    transcript: str
    subject: Optional[str] = None


class URLRequest(BaseModel):
    url: str


# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"status": "Scrib API is running", "version": "2.0.0"}


@app.get("/health")
def health():
    return {"status": "ok"}


# ── Transcription Endpoint ────────────────────────────────────────────────────

@app.post("/api/transcribe")
async def transcribe_file(audio: UploadFile = File(None), file: UploadFile = File(None)):
    """
    Upload an audio file → returns transcript + speaker segments.
    Flutter calls this first after recording a lecture.
    Accepts field name 'audio' (Flutter) or 'file' (API docs/tests).
    """
    upload = audio or file
    if upload is None:
        raise HTTPException(status_code=400, detail="No audio file provided. Use field name 'audio' or 'file'.")

    filename = upload.filename or "audio"
    _, ext = os.path.splitext(filename)
    if not ext:
        ext = ".m4a"

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=ext)
    try:
        shutil.copyfileobj(upload.file, tmp)
        tmp.close()

        size = os.path.getsize(tmp.name)
        if size == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty")

        print(f"Received: {filename} ({size/1024/1024:.2f} MB)")

        result = transcribe_audio(tmp.name)

        if not result["success"]:
            raise HTTPException(status_code=500, detail=result["user_message"])

        return result

    finally:
        try:
            os.unlink(tmp.name)
        except Exception:
            pass


@app.post("/api/transcribe-url")
def transcribe_from_url(request: URLRequest):
    """Transcribe audio from a direct audio URL (not YouTube)."""
    if not request.url.startswith(("http://", "https://")):
        raise HTTPException(status_code=400, detail="Invalid URL")

    result = transcribe_audio(request.url)
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["user_message"])
    return result


# ── Notes Generation Endpoint ─────────────────────────────────────────────────

@app.post("/api/notes")
def generate_study_notes(request: NotesRequest):
    """
    Send a transcript → returns structured study notes.
    Flutter calls this after receiving the transcript from /api/transcribe.
    """
    if not request.transcript.strip():
        raise HTTPException(status_code=400, detail="Transcript cannot be empty")

    result = generate_notes(request.transcript, subject=request.subject)

    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["user_message"])

    return result


# ── Run ───────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
