
class AppConstants {
  // Backend base URL. For Android emulator use 10.0.2.2 to reach host machine.
  // Override with --dart-define=BACKEND_BASE_URL=http://<your-ip>:8787
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://scrib-backend.fly.dev',
  );

    // ─── Backend Endpoints ────────────────────────────────────────────────────
    static const String transcribeEndpoint = '$backendBaseUrl/api/transcribe';
    static const String generateNotesEndpoint = '$backendBaseUrl/api/notes';

  // ─── App Strings ──────────────────────────────────────────────────────────
  static const String appName = 'Scrib';
  static const String tagline = 'Focus on learning. We handle the notes.';

  // ─── Recording limits ─────────────────────────────────────────────────────
  static const int maxRecordingMinutes = 180; // 3 hours max
}