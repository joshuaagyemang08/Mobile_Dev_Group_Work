// lib/providers/lecture_provider.dart
//
// Central state manager for all lectures in the app.
// Persists lectures to SharedPreferences so they survive app restarts.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../services/ai_notes_service.dart';
import 'package:uuid/uuid.dart';

class LectureProvider extends ChangeNotifier {
  final _audioService = AudioService();
  final _transcriptionService = TranscriptionService();
  final _aiNotesService = AiNotesService();
  final _uuid = const Uuid();

  List<Lecture> _lectures = [];
  List<Lecture> get lectures => List.unmodifiable(_lectures);

  Lecture? get activeLecture => _lectures.isNotEmpty ? _lectures.last : null;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Stream<Duration> get recordingDurationStream =>
      _audioService.durationStream;

  // ─── Persistence ──────────────────────────────────────────────────────────

  static const _storageKey = 'scrib_lectures';

  Future<void> loadLectures() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? [];
    _lectures = stored.map(Lecture.fromJsonString).toList();
    notifyListeners();
  }

  Future<void> _saveLectures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _lectures.map((l) => l.toJsonString()).toList(),
    );
  }

  // ─── Recording lifecycle ──────────────────────────────────────────────────

  Future<void> startRecording({
    required String title,
    String? subject,
  }) async {
    final path = await _audioService.startRecording();
    if (path == null) return; // permission denied

    _isRecording = true;
    notifyListeners();
  }

  Future<void> pauseRecording() async {
    await _audioService.pauseRecording();
  }

  Future<void> resumeRecording() async {
    await _audioService.resumeRecording();
  }

  /// Stops recording, creates the lecture object, and kicks off processing.
  Future<void> stopRecordingAndProcess({
    required String title,
    String? subject,
  }) async {
    final result = await _audioService.stopRecording();
    _isRecording = false;
    notifyListeners();

    if (result == null) return;

    final lecture = Lecture(
      id: _uuid.v4(),
      title: title,
      subject: subject,
      recordedAt: DateTime.now(),
      duration: result.duration,
      audioPath: result.path,
      status: LectureStatus.uploading,
    );

    _lectures.insert(0, lecture);
    await _saveLectures();
    notifyListeners();

    // Process in the background — UI will react to status changes
    await _processLecture(lecture);
  }

  // ─── Processing pipeline ──────────────────────────────────────────────────

  Future<void> _processLecture(Lecture lecture) async {
    try {
      // Step 1: Upload & transcribe
      _updateLecture(lecture.copyWith(status: LectureStatus.uploading));

      final transcript = await _transcriptionService.transcribeAudio(
        lecture.audioPath,
        onUploadProgress: (p) {
          _updateLecture(
              lecture.copyWith(status: LectureStatus.uploading, uploadProgress: p));
        },
        onTranscriptionStatus: (s) {
          _updateLecture(lecture.copyWith(status: LectureStatus.transcribing));
        },
      );

      _updateLecture(lecture.copyWith(
        status: LectureStatus.generatingNotes,
        transcript: transcript,
      ));

      // Step 2: Generate notes
      final notes = await _aiNotesService.generateNotes(transcript);

      _updateLecture(lecture.copyWith(
        status: LectureStatus.completed,
        notes: notes,
      ));
    } catch (e) {
      _updateLecture(lecture.copyWith(
        status: LectureStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  void _updateLecture(Lecture updated) {
    final idx = _lectures.indexWhere((l) => l.id == updated.id);
    if (idx != -1) {
      _lectures[idx] = updated;
      _saveLectures();
      notifyListeners();
    }
  }

  Future<void> deleteLecture(String id) async {
    _lectures.removeWhere((l) => l.id == id);
    await _saveLectures();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}