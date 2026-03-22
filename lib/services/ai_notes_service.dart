// lib/services/ai_notes_service.dart
//
// Sends a transcript to Claude (Anthropic) and parses the structured
// JSON response into a LectureNotes object.
//
// ════════════════════════════════════════════════════════════════════════════
// TEAMMATE TASK (Member 3)
// 1. Refine the system prompt to improve note quality and formatting.
// 2. Add a follow-up call that generates a "quiz" (multiple-choice questions).
// 3. Add a streaming version so the UI can show notes appearing in real time.
// 4. Handle very long transcripts by splitting and merging (see TODO below).
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/lecture.dart';

class AiNotesService {
  static const _systemPrompt = '''
You are Scrib, an expert academic note-taker and educator. Your job is to turn raw lecture transcripts into beautiful, student-friendly study materials.

Given a lecture transcript, return ONLY a valid JSON object (no markdown code fences, no preamble) matching this schema:

{
  "summary": "A 3–5 sentence executive summary of the entire lecture.",
  "topics": ["Topic 1", "Topic 2", "Topic 3"],
  "fullNotes": "Full Markdown-formatted notes. Use ## for major topics, ### for subtopics, **bold** for key terms, bullet lists for details, > blockquotes for important quotes or definitions, and tables where comparisons are useful. Make this genuinely useful for studying.",
  "keyPoints": [
    "Concise key takeaway 1",
    "Concise key takeaway 2"
  ],
  "flashcards": [
    { "question": "What is X?", "answer": "X is..." },
    { "question": "What is Y?", "answer": "Y is..." }
  ]
}

Rules:
- Aim for 8–15 flashcards covering the most important concepts.
- Key points should be self-contained (understandable without reading the notes).
- The fullNotes should be comprehensive — a student who missed the lecture should be able to study from them.
- Format the notes beautifully with clear hierarchy.
- If the transcript mentions formulas, render them in LaTeX-style (e.g. \$E = mc^2\$).
- Do NOT include anything outside the JSON object.
''';

  // ─── Generate notes from transcript ───────────────────────────────────────

  Future<LectureNotes> generateNotes(String transcript) async {
    // TODO (Member 3): For transcripts > 15,000 words, split into chunks,
    // generate notes per chunk, then merge with a second prompt.
    // Right now this sends the whole transcript in one shot.

    final response = await http.post(
      Uri.parse(AppConstants.anthropicMessagesUrl),
      headers: {
        'content-type': 'application/json',
        'x-api-key': AppConstants.anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': AppConstants.anthropicModel,
        'max_tokens': 8192,
        'system': _systemPrompt,
        'messages': [
          {
            'role': 'user',
            'content':
                'Here is the lecture transcript. Generate the notes now:\n\n$transcript',
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'AI notes generation failed (${response.statusCode}): ${response.body}');
    }

    final responseJson =
        jsonDecode(response.body) as Map<String, dynamic>;
    final contentBlocks =
        responseJson['content'] as List<dynamic>;

    final rawText = contentBlocks
        .where((b) => (b as Map)['type'] == 'text')
        .map((b) => (b as Map)['text'] as String)
        .join('');

    // Parse JSON — strip any accidental markdown fences just in case
    final cleanJson = rawText
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final notesJson = jsonDecode(cleanJson) as Map<String, dynamic>;
    return LectureNotes.fromJson(notesJson);
  }

  // ─── Generate a quiz (TODO for Member 3) ─────────────────────────────────
  // Future<List<QuizQuestion>> generateQuiz(LectureNotes notes) async { ... }
}