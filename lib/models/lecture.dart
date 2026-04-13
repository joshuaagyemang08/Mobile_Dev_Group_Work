// lib/models/lecture.dart

import 'dart:convert';

enum LectureStatus {
  recorded,
  uploading,
  transcribing,
  generatingNotes,
  completed,
  failed,
}

class Flashcard {
  final String question;
  final String answer;

  const Flashcard({required this.question, required this.answer});

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        question: json['question'] as String,
        answer: json['answer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };
}

class LectureNotes {
  final String summary;
  final String fullNotes; // Markdown formatted
  final List<String> keyPoints;
  final List<Flashcard> flashcards;
  final List<String> topics;

  const LectureNotes({
    required this.summary,
    required this.fullNotes,
    required this.keyPoints,
    required this.flashcards,
    required this.topics,
  });

  factory LectureNotes.fromJson(Map<String, dynamic> json) => LectureNotes(
        summary: json['summary'] as String? ?? '',
        fullNotes: json['fullNotes'] as String? ?? '',
        keyPoints: List<String>.from(json['keyPoints'] as List? ?? []),
        flashcards: (json['flashcards'] as List? ?? [])
            .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
            .toList(),
        topics: List<String>.from(json['topics'] as List? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'fullNotes': fullNotes,
        'keyPoints': keyPoints,
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'topics': topics,
      };
}

class Lecture {
  final String id;
  final String title;
  final String? subject;
  final DateTime recordedAt;
  final Duration duration;
  final String audioPath;
  LectureStatus status;
  String? transcript;
  LectureNotes? notes;
  String? errorMessage;
  double uploadProgress; // 0.0 to 1.0
  List<String> photoPaths; // attached whiteboard/slide photos

  Lecture({
    required this.id,
    required this.title,
    this.subject,
    required this.recordedAt,
    required this.duration,
    required this.audioPath,
    this.status = LectureStatus.recorded,
    this.transcript,
    this.notes,
    this.errorMessage,
    this.uploadProgress = 0.0,
    this.photoPaths = const [],
  });

  Lecture copyWith({
    LectureStatus? status,
    String? transcript,
    LectureNotes? notes,
    String? errorMessage,
    double? uploadProgress,
    List<String>? photoPaths,
  }) {
    return Lecture(
      id: id,
      title: title,
      subject: subject,
      recordedAt: recordedAt,
      duration: duration,
      audioPath: audioPath,
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      notes: notes ?? this.notes,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String?,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        duration: Duration(seconds: json['durationSeconds'] as int),
        audioPath: json['audioPath'] as String,
        status: LectureStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LectureStatus.recorded,
        ),
        transcript: json['transcript'] as String?,
        notes: json['notes'] != null
            ? LectureNotes.fromJson(
                json['notes'] as Map<String, dynamic>)
            : null,
        photoPaths: List<String>.from(json['photoPaths'] as List? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'recordedAt': recordedAt.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'audioPath': audioPath,
        'status': status.name,
        'transcript': transcript,
        'notes': notes?.toJson(),
        'photoPaths': photoPaths,
      };

  // ── Supabase (snake_case columns) ─────────────────────────────────────────

  Map<String, dynamic> toSupabaseJson(String userId) => {
        'id': id,
        'user_id': userId,
        'title': title,
        'subject': subject,
        'recorded_at': recordedAt.toIso8601String(),
        'duration_seconds': duration.inSeconds,
        'audio_path': audioPath,
        'status': status.name,
        'transcript': transcript,
        'notes': notes?.toJson(),
        'photo_paths': photoPaths,
        'error_message': errorMessage,
        'upload_progress': uploadProgress,
      };

  factory Lecture.fromSupabaseJson(Map<String, dynamic> json) => Lecture(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String?,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        duration: Duration(seconds: json['duration_seconds'] as int),
        audioPath: json['audio_path'] as String,
        status: LectureStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LectureStatus.recorded,
        ),
        transcript: json['transcript'] as String?,
        notes: json['notes'] != null
            ? LectureNotes.fromJson(json['notes'] as Map<String, dynamic>)
            : null,
        photoPaths: List<String>.from(json['photo_paths'] as List? ?? []),
        errorMessage: json['error_message'] as String?,
        uploadProgress:
            (json['upload_progress'] as num?)?.toDouble() ?? 0.0,
      );

  // ── Local (SharedPreferences fallback) ───────────────────────────────────

  String toJsonString() => jsonEncode(toJson());
  factory Lecture.fromJsonString(String s) =>
      Lecture.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
