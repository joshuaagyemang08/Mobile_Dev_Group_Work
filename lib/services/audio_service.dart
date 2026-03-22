// lib/services/audio_service.dart
//
// Handles microphone permission, starting/stopping recording, and returning
// the path to the saved audio file.  Uses the `record` package.

import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final _uuid = const Uuid();

  String? _currentFilePath;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  /// Live elapsed-time stream – listen to this to update the UI timer
  Stream<Duration> get durationStream => _durationController.stream;

  bool get isRecording => _recorder.isRecording() as bool;

  // ─── Permissions ──────────────────────────────────────────────────────────

  /// Returns true only when the mic permission is granted.
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ─── Recording ────────────────────────────────────────────────────────────

  /// Starts a new recording and returns the file path where audio is saved.
  Future<String?> startRecording() async {
    final granted = await requestPermission();
    if (!granted) return null;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'lecture_${_uuid.v4()}.m4a';
    _currentFilePath = '${dir.path}/$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000, // Lower bitrate = smaller files for voice
        sampleRate: 16000, // 16 kHz is plenty for speech
      ),
      path: _currentFilePath!,
    );

    _recordingStartTime = DateTime.now();
    _startDurationTimer();

    return _currentFilePath;
  }

  /// Pauses the recording so students can mute during breaks.
  Future<void> pauseRecording() async {
    await _recorder.pause();
    _durationTimer?.cancel();
  }

  /// Resumes a paused recording.
  Future<void> resumeRecording() async {
    await _recorder.resume();
    _startDurationTimer();
  }

  /// Stops the recording and returns the file path + duration.
  Future<({String path, Duration duration})?> stopRecording() async {
    _durationTimer?.cancel();
    final path = await _recorder.stop();
    final duration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;

    _recordingStartTime = null;
    _currentFilePath = null;

    if (path == null) return null;
    return (path: path, duration: duration);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStartTime != null) {
        _durationController
            .add(DateTime.now().difference(_recordingStartTime!));
      }
    });
  }

  void dispose() {
    _durationTimer?.cancel();
    _durationController.close();
    _recorder.dispose();
  }
}