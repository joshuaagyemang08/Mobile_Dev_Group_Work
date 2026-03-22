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

class TranscriptionService {
  static const _headers = {
    'authorization': AppConstants.assemblyAiApiKey,
    'content-type': 'application/json',
  };

  // ─── Step 1: Upload audio file ────────────────────────────────────────────

  /// Uploads a local audio file to AssemblyAI's CDN.
  /// [onProgress] fires with a value between 0.0 and 1.0.
  Future<String> uploadAudio(
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw TranscriptionException('Audio file not found: $filePath');
    }

    final fileSize = file.lengthSync();
    final bytes = await file.readAsBytes();

    // AssemblyAI accepts a raw binary POST for the upload endpoint.
    final request = http.StreamedRequest('POST', Uri.parse(AppConstants.assemblyUploadUrl))
      ..headers.addAll({
        'authorization': AppConstants.assemblyAiApiKey,
        'content-type': 'application/octet-stream',
        'content-length': '$fileSize',
        'transfer-encoding': 'chunked',
      });

    // Stream bytes in chunks and report progress.
    const chunkSize = 5242880; // 5 MB per chunk
    int uploaded = 0;
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      final chunk = bytes.sublist(i, end);
      request.sink.add(chunk);
      uploaded += chunk.length;
      onProgress?.call(uploaded / fileSize);
    }
    await request.sink.close();

    final response = await http.Client().send(request);
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw TranscriptionException('Upload failed (${response.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final uploadUrl = json['upload_url'] as String?;
    if (uploadUrl == null) {
      throw TranscriptionException('AssemblyAI did not return an upload_url');
    }
    return uploadUrl;
  }

  // ─── Step 2: Request transcription ────────────────────────────────────────

  /// Submits a transcription job to AssemblyAI and returns the job ID.
  Future<String> requestTranscription(String uploadUrl) async {
    final response = await http.post(
      Uri.parse(AppConstants.assemblyTranscriptUrl),
      headers: _headers,
      body: jsonEncode({
        'audio_url': uploadUrl,
        'speaker_labels': true, // diarisation — helps distinguish lecturer vs students
        'auto_chapters': true,  // chapter markers for long lectures
        'punctuate': true,
        'format_text': true,
      }),
    );

    if (response.statusCode != 200) {
      throw TranscriptionException(
          'Transcription request failed (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final id = json['id'] as String?;
    if (id == null) throw const TranscriptionException('No transcription ID returned');
    return id;
  }

  // ─── Step 3: Poll for completion ──────────────────────────────────────────

  /// Polls AssemblyAI every 10 seconds until the transcript is ready.
  /// Returns the full transcript text.
  ///
  /// TODO (Member 2):
  ///   1. Parse `utterances` from the response to separate speaker turns.
  ///   2. Label "Speaker A" as the lecturer if they have the most total words.
  ///   3. Surface chapters (json['chapters']) so the notes service can use them.
  ///   4. Handle the 'error' status and surface a user-friendly message.
  Future<String> pollForTranscript(
    String transcriptId, {
    void Function(String status)? onStatusUpdate,
  }) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 10));

      final response = await http.get(
        Uri.parse('${AppConstants.assemblyTranscriptUrl}/$transcriptId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw TranscriptionException(
            'Polling failed (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String;
      onStatusUpdate?.call(status);

      switch (status) {
        case 'completed':
          final text = json['text'] as String?;
          if (text == null || text.isEmpty) {
            throw const TranscriptionException('Transcript is empty');
          }
          return text;

        case 'error':
          final err = json['error'] as String? ?? 'Unknown transcription error';
          throw TranscriptionException(err);

        case 'queued':
        case 'processing':
          // Still working — loop again
          continue;

        default:
          throw TranscriptionException('Unknown status: $status');
      }
    }
  }

  // ─── Convenience: run the full pipeline ───────────────────────────────────

  /// Uploads audio and transcribes it, calling back at each stage.
  Future<String> transcribeAudio(
    String filePath, {
    void Function(double progress)? onUploadProgress,
    void Function(String status)? onTranscriptionStatus,
  }) async {
    final uploadUrl = await uploadAudio(filePath, onProgress: onUploadProgress);
    final jobId = await requestTranscription(uploadUrl);
    return pollForTranscript(jobId, onStatusUpdate: onTranscriptionStatus);
  }
}