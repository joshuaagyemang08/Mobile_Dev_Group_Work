
class AppConstants {
  // ─── API Keys (provide using --dart-define at build/run time) ─────────────
  // AssemblyAI — for transcription: https://www.assemblyai.com
  static const String assemblyAiApiKey = String.fromEnvironment(
    'ASSEMBLYAI_KEY',
    defaultValue: '',
  );

  // Anthropic — for AI note generation: https://console.anthropic.com
  static const String anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_KEY',
    defaultValue: '',
  );

  // ─── AssemblyAI Endpoints ─────────────────────────────────────────────────
  static const String assemblyUploadUrl =
      'https://api.assemblyai.com/v2/upload';
  static const String assemblyTranscriptUrl =
      'https://api.assemblyai.com/v2/transcript';

  // ─── Anthropic Endpoint ───────────────────────────────────────────────────
  static const String anthropicMessagesUrl =
      'https://api.anthropic.com/v1/messages';
  static const String anthropicModel = 'claude-opus-4-5';

  // ─── App Strings ──────────────────────────────────────────────────────────
  static const String appName = 'Scrib';
  static const String tagline = 'Focus on learning. We handle the notes.';

  // ─── Recording limits ─────────────────────────────────────────────────────
  static const int maxRecordingMinutes = 180; // 3 hours max
}