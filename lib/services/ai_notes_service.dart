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
  // ─── Generate notes from transcript ───────────────────────────────────────

  Future<LectureNotes> generateNotes(String transcript) async {
    final response = await http.post(
      Uri.parse(AppConstants.generateNotesEndpoint),
      headers: {
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'transcript': transcript,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'AI notes generation failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // New Python backend response: { success, payload: { title, summary, key_points, flashcards, takeaways, topics } }
    final payload = decoded.containsKey('payload')
        ? decoded['payload'] as Map<String, dynamic>
        : decoded;

    // Map Python backend fields to LectureNotes model
    final notesJson = {
      'summary': payload['summary'] ?? payload['overview'] ?? '',
      'fullNotes': _buildFullNotes(payload),
      'keyPoints': _parseKeyPoints(payload['key_points'] as String? ?? ''),
      'flashcards': payload['flashcards'] ?? [],
      'topics': payload['topics'] ?? [],
    };

    return LectureNotes.fromJson(notesJson);
  }

  // ─── Generate a quiz (TODO for Member 3) ─────────────────────────────────
  // Future<List<QuizQuestion>> generateQuiz(LectureNotes notes) async { ... }

  /// Builds a markdown-formatted full notes string from the payload fields.
  /// Intentionally excludes the summary — that lives in the Summary tab.
  /// Notes tab = detailed study content: key points + takeaways.
  String _buildFullNotes(Map<String, dynamic> payload) {
    final buffer = StringBuffer();
    final title = payload['title'] as String? ?? '';
    final keyPoints = payload['key_points'] as String? ?? '';
    final takeaways = payload['takeaways'] as String? ?? '';

    if (title.isNotEmpty) buffer.writeln('# $title\n');
    if (keyPoints.isNotEmpty) buffer.writeln('## Key Points\n$keyPoints\n');
    if (takeaways.isNotEmpty) buffer.writeln('## Key Takeaways\n$takeaways\n');

    return buffer.toString();
  }

  /// Parses a numbered string list into a List<String>.
  List<String> _parseKeyPoints(String raw) {
    return raw
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }
}