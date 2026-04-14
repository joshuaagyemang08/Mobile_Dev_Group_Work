# python_backend/notes.py
# Generates structured study notes from a transcript using GPT-4o-mini

import os
from typing import Optional
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY not found in environment variables")


def generate_notes(transcript: str, subject: Optional[str] = None) -> dict:
    """
    Generate structured study notes from a lecture transcript.

    Args:
        transcript: The formatted transcript text (with speaker labels)
        subject: Optional subject/course name for context

    Returns:
        dict with success status and structured notes payload
    """
    if not transcript or not transcript.strip():
        return {
            "success": False,
            "dev_message": "Empty transcript provided",
            "user_message": "No transcript content to generate notes from.",
            "payload": {},
        }

    print("\n🎯 GENERATING STUDY NOTES")

    context = f"This is a lecture transcript" + (f" for {subject}." if subject else ".")

    try:
        llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.3, api_key=OPENAI_API_KEY)

        def ask(system: str, user: str) -> str:
            return llm.invoke([
                SystemMessage(content=system),
                HumanMessage(content=user),
            ]).content.strip()

        print("📝 Generating title...")
        title = ask(
            "Return only a short lecture title (max 6 words). No quotes or extra text.",
            f"{context}\n\nGenerate a title:\n\n{transcript[:300]}",
        ).strip('"').strip("'")

        print("📋 Generating summary...")
        summary = ask(
            "Return a concise 3-5 sentence summary of the lecture. Focus on the main concepts taught.",
            f"{context}\n\nSummarize this lecture:\n\n{transcript}",
        )

        print("🎯 Extracting key points...")
        key_points = ask(
            "Return a numbered list of 5-8 key concepts or points taught in this lecture (1. 2. 3. etc.). Be specific.",
            f"{context}\n\nList the key points:\n\n{transcript}",
        )

        print("🃏 Generating flashcards...")
        flashcards_raw = ask(
            """Generate 5-8 flashcards from this lecture.
Format EXACTLY like this (one per line, no extra text):
Q: [question] | A: [answer]
Q: [question] | A: [answer]""",
            f"{context}\n\nGenerate flashcards:\n\n{transcript}",
        )

        print("✅ Extracting takeaways...")
        takeaways = ask(
            "List 3-5 key takeaways a student should remember from this lecture. Use bullet points (•).",
            f"{context}\n\nKey takeaways:\n\n{transcript}",
        )

        print("📚 Identifying topics...")
        topics = ask(
            "List the main topics/concepts covered in this lecture, comma separated. Max 8 topics.",
            f"{context}\n\nList topics covered:\n\n{transcript}",
        )

        # Parse flashcards into structured format
        flashcards = []
        for line in flashcards_raw.split("\n"):
            line = line.strip()
            if line.startswith("Q:") and " | A:" in line:
                parts = line.split(" | A:")
                question = parts[0].replace("Q:", "").strip()
                answer = parts[1].strip() if len(parts) > 1 else ""
                if question and answer:
                    flashcards.append({"question": question, "answer": answer})

        # Parse topics into list
        topics_list = [t.strip() for t in topics.split(",") if t.strip()]

        print(f"Notes generated — {len(flashcards)} flashcards, {len(topics_list)} topics")

        return {
            "success": True,
            "dev_message": "Notes generated successfully",
            "user_message": "Study notes are ready!",
            "payload": {
                "title": title,
                "summary": summary,
                "key_points": key_points,
                "flashcards": flashcards,
                "takeaways": takeaways,
                "topics": topics_list,
            },
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"❌ Notes generation error: {e}")
        return {
            "success": False,
            "dev_message": f"Notes generation error: {str(e)}",
            "user_message": "Failed to generate notes. Please try again.",
            "payload": {},
        }
