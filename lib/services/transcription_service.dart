// lib/services/transcription_service.dart
//
// Handles uploading long audio files to AssemblyAI and polling for the
// finished transcript.  AssemblyAI is chosen because it:
//   • accepts files up to several hours long
//   • processes asynchronously (no timeout issues)
//   • has speaker diarisation, which helps separate lecturer from questions
//
// ════════════════════════════════════════════════════════════════════════════
// TEAMMATE TASK (Member 2)
// Implement the body of _pollForTranscript(), handle error states,
// and add speaker-diarisation parsing so the notes service knows when
// the lecturer is speaking vs a student asking a question.
// See the TODO comments below.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class TranscriptionException implements Exception {
  final String message;
  const TranscriptionException(this.message);
  @override
  String toString() => 'TranscriptionException: $message';
}

/// Represents a single speaker turn in the transcript.
class SpeakerTurn {
  final String speaker; // 'Lecturer' or 'Student'
  final String text;
  const SpeakerTurn({required this.speaker, required this.text});
}

/// Parses AssemblyAI utterances and labels the most-talking speaker as Lecturer.
List<SpeakerTurn> parseSpeakers(List<dynamic> utterances) {
  // Count total words spoken by each speaker
  final wordCount = <String, int>{};
  for (final u in utterances) {
    final speaker = u['speaker'] as String? ?? 'Unknown';
    final text = u['text'] as String? ?? '';
    wordCount[speaker] = (wordCount[speaker] ?? 0) + text.split(' ').length;
  }

  // The speaker with the most words is the lecturer
  final lecturer = wordCount.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;

  return utterances.map((u) {
    final speaker = u['speaker'] as String? ?? 'Unknown';
    final text = u['text'] as String? ?? '';
    return SpeakerTurn(
      speaker: speaker == lecturer ? 'Lecturer' : 'Student',
      text: text,
    );
  }).toList();
}

class TranscriptionService {
  /// Uploads a local audio file to backend and returns transcript text.
  Future<String> transcribeAudio(
    String filePath, {
    void Function(double progress)? onProgress,
    void Function(String status)? onTranscriptionStatus,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw TranscriptionException('Audio file not found: $filePath');
    }

    onTranscriptionStatus?.call('uploading');
    onProgress?.call(0.1);

    // Retry upload up to 3 times on failure (e.g. bad internet connection)
    const maxRetries = 3;
    int attempt = 0;
    late http.StreamedResponse streamed;
    late String responseBody;

    while (attempt < maxRetries) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(AppConstants.transcribeEndpoint),
        );
        request.files.add(await http.MultipartFile.fromPath('audio', filePath));

        streamed = await request.send();
        responseBody = await streamed.stream.bytesToString();
        break; // success — exit the retry loop
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          throw TranscriptionException(
              'Upload failed after $maxRetries attempts: $e');
        }
        onTranscriptionStatus?.call('retrying (attempt $attempt)');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (streamed.statusCode != 200) {
      throw TranscriptionException(
          'Transcription failed (${streamed.statusCode}): $responseBody');
    }

    onProgress?.call(1.0);
    onTranscriptionStatus?.call('completed');

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

    // New Python backend response: { success, payload: { transcript, ... } }
    if (decoded.containsKey('payload')) {
      final payload = decoded['payload'] as Map<String, dynamic>?;
      final transcript = payload?['transcript'] as String?;
      if (transcript == null || transcript.isEmpty) {
        throw const TranscriptionException('Transcript is empty');
      }
      return transcript;
    }

    // Fallback for old response format
    final transcript = decoded['transcript'] as String?;
    if (transcript == null || transcript.isEmpty) {
      throw const TranscriptionException('Transcript is empty');
    }
    return transcript;
  }
}