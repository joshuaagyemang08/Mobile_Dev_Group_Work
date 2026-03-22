// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/lecture.dart';
import '../providers/lecture_provider.dart';
import 'recording_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved lectures when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LectureProvider>().loadLectures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('✏️ ', style: TextStyle(fontSize: 20)),
            Text('Scrib'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {/* TODO: Settings screen */},
          ),
        ],
      ),
      body: Consumer<LectureProvider>(
        builder: (context, provider, _) {
          final lectures = provider.lectures;

          if (lectures.isEmpty) {
            return _EmptyState(onRecord: () => _startRecording(context));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatsBar(lectures: lectures),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Your Lectures',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: lectures.length,
                  itemBuilder: (context, index) =>
                      _LectureCard(lecture: lectures[index]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startRecording(context),
        icon: const Icon(Icons.mic),
        label: const Text('Record Lecture'),
      ),
    );
  }

  void _startRecording(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordingScreen()),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRecord});
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎙️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No lectures yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to record your first lecture',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.mic),
            label: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.lectures});
  final List<Lecture> lectures;

  @override
  Widget build(BuildContext context) {
    final completed = lectures.where((l) => l.status == LectureStatus.completed).length;
    final totalHours = lectures
        .fold(Duration.zero, (acc, l) => acc + l.duration)
        .inHours;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ScribTheme.primary, Color(0xFF7B6FE9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Lectures', value: '${lectures.length}'),
          _Stat(label: 'Notes Ready', value: '$completed'),
          _Stat(label: 'Hours Recorded', value: '$totalHours'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

// ─── Lecture Card ─────────────────────────────────────────────────────────────

class _LectureCard extends StatelessWidget {
  const _LectureCard({required this.lecture});
  final Lecture lecture;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: lecture.status == LectureStatus.completed
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NotesScreen(lecture: lecture)),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _StatusIcon(status: lecture.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lecture.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lecture.subject != null) ...[
                          _Chip(label: lecture.subject!),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _formatDuration(lecture.duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${DateFormat('MMM d').format(lecture.recordedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (lecture.status != LectureStatus.completed &&
                        lecture.status != LectureStatus.failed) ...[
                      const SizedBox(height: 8),
                      _ProcessingIndicator(lecture: lecture),
                    ],
                  ],
                ),
              ),
              if (lecture.status == LectureStatus.completed)
                const Icon(Icons.chevron_right,
                    color: ScribTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final LectureStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      LectureStatus.completed => (Icons.check_circle, ScribTheme.secondary),
      LectureStatus.failed => (Icons.error, ScribTheme.error),
      _ => (Icons.hourglass_empty, ScribTheme.primary),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  const _ProcessingIndicator({required this.lecture});
  final Lecture lecture;

  @override
  Widget build(BuildContext context) {
    final label = switch (lecture.status) {
      LectureStatus.uploading =>
        'Uploading… ${(lecture.uploadProgress * 100).toStringAsFixed(0)}%',
      LectureStatus.transcribing => 'Transcribing…',
      LectureStatus.generatingNotes => 'Generating notes…',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: lecture.status == LectureStatus.uploading
              ? lecture.uploadProgress
              : null,
          backgroundColor: ScribTheme.surfaceVariant,
          color: ScribTheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: ScribTheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: ScribTheme.primary,
                fontWeight: FontWeight.w500)),
      );
}