// lib/providers/lecture_provider.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lecture.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../services/ai_notes_service.dart';
import '../services/notification_service.dart';
import '../services/photo_storage_service.dart';
import 'package:uuid/uuid.dart';

class LectureProvider extends ChangeNotifier {
  final _audioService = AudioService();
  final _transcriptionService = TranscriptionService();
  final _aiNotesService = AiNotesService();
  final _photoStorageService = PhotoStorageService();
  final _uuid = const Uuid();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  List<Lecture> _lectures = [];
  List<Lecture> get lectures => List.unmodifiable(_lectures);

  Lecture? get activeLecture => _lectures.isNotEmpty ? _lectures.last : null;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Stream<Duration> get recordingDurationStream =>
      _audioService.durationStream;

  // ─── Load from Supabase ───────────────────────────────────────────────────

  Future<void> loadLectures() async {
    try {
      final uid = _userId;
      if (uid == null) return;

      final response = await _db
          .from('lectures')
          .select()
          .eq('user_id', uid)
          .order('recorded_at', ascending: false);

      _lectures = (response as List)
          .map((json) => Lecture.fromSupabaseJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading lectures: $e');
    }
  }

  // ─── Upsert single lecture to Supabase ───────────────────────────────────

  Future<void> _upsertLecture(Lecture lecture) async {
    try {
      final uid = _userId;
      if (uid == null) return;
      await _db.from('lectures').upsert(lecture.toSupabaseJson(uid));
    } catch (e) {
      debugPrint('Error saving lecture: $e');
    }
  }

  // ─── Recording lifecycle ──────────────────────────────────────────────────

  Future<void> startRecording({
    required String title,
    String? subject,
  }) async {
    final path = await _audioService.startRecording();
    if (path == null) return;
    _isRecording = true;
    notifyListeners();
  }

  Future<void> pauseRecording() async {
    await _audioService.pauseRecording();
  }

  Future<void> resumeRecording() async {
    await _audioService.resumeRecording();
  }

  Future<String?> stopRecordingAndProcess({
    required String title,
    String? subject,
  }) async {
    final result = await _audioService.stopRecording();
    _isRecording = false;
    notifyListeners();

    if (result == null) return null;

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
    notifyListeners();
    await _upsertLecture(lecture);

    // Fire and forget
    _processLecture(lecture);

    return lecture.id;
  }

  // ─── Processing pipeline ──────────────────────────────────────────────────

  Future<void> _processLecture(Lecture lecture) async {
    try {
      _updateLecture(lecture.copyWith(status: LectureStatus.uploading));

      final transcript = await _transcriptionService.transcribeAudio(
        lecture.audioPath,
        onProgress: (p) {
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

      final notes = await _aiNotesService.generateNotes(transcript);

      _updateLecture(lecture.copyWith(
        status: LectureStatus.completed,
        transcript: transcript,
        notes: notes,
      ));
      await NotificationService.showNotesReady(lecture.title);
    } catch (e) {
      _updateLecture(lecture.copyWith(
        status: LectureStatus.failed,
        errorMessage: e.toString(),
      ));
      await NotificationService.showProcessingFailed(lecture.title);
    }
  }

  void _updateLecture(Lecture updated) {
    final idx = _lectures.indexWhere((l) => l.id == updated.id);
    if (idx != -1) {
      _lectures[idx] = updated;
      notifyListeners();
      _upsertLecture(updated);
    }
  }

  Future<void> retryLecture(String id) async {
    final idx = _lectures.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    await _processLecture(_lectures[idx]);
  }

  Future<void> deleteLecture(String id) async {
    _lectures.removeWhere((l) => l.id == id);
    notifyListeners();
    try {
      await _db.from('lectures').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting lecture: $e');
    }
  }

  Future<void> addPhoto(String lectureId, String photoPath) async {
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx == -1) return;

    String storedPath = photoPath;
    try {
      storedPath = await _photoStorageService.uploadLecturePhoto(
        lectureId: lectureId,
        localPath: photoPath,
      );
    } catch (e) {
      // Fallback: keep a local file path so user can still attach/view photos.
      debugPrint('Cloud photo upload failed, using local fallback: $e');
    }

    final updated = List<String>.from(_lectures[idx].photoPaths)
      ..add(storedPath);
    _updateLecture(_lectures[idx].copyWith(photoPaths: updated));
  }

  Future<void> deletePhoto(String lectureId, String photoPath) async {
    final idx = _lectures.indexWhere((l) => l.id == lectureId);
    if (idx == -1) return;

    try {
      await _photoStorageService.deleteByReference(photoPath);
    } catch (e) {
      debugPrint('Error deleting photo from storage: $e');
    }

    final updated = List<String>.from(_lectures[idx].photoPaths)
      ..remove(photoPath);
    _updateLecture(_lectures[idx].copyWith(photoPaths: updated));
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
