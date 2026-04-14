// lib/screens/processing_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/lecture.dart';
import '../providers/lecture_provider.dart';
import 'notes_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String lectureId;
  const ProcessingScreen({super.key, required this.lectureId});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;

  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat(reverse: true);

  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScribTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.9,
                    colors: [
                      ScribTheme.secondary
                          .withOpacity(0.05 + _glowController.value * 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Consumer<LectureProvider>(
              builder: (context, provider, _) {
                final lecture = provider.lectures
                    .where((l) => l.id == widget.lectureId)
                    .firstOrNull;

                if (lecture == null) {
                  return const Center(
                    child: Text('Lecture not found',
                        style: TextStyle(color: ScribTheme.textSecondary)),
                  );
                }

                if (lecture.status == LectureStatus.completed && !_navigated) {
                  _navigated = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a, __) =>
                              NotesScreen(lecture: lecture),
                          transitionsBuilder: (_, a, __, child) =>
                              FadeTransition(opacity: a, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 400),
                        ),
                      );
                    }
                  });
                }

                return _buildBody(context, lecture, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, Lecture lecture, LectureProvider provider) {
    final isFailed = lecture.status == LectureStatus.failed;

    return Column(
      children: [
        SizedBox(
          height: 3,
          child: isFailed
              ? Container(color: ScribTheme.error.withOpacity(0.5))
              : const LinearProgressIndicator(
                  value: null,
                  backgroundColor: ScribTheme.surfaceVariant,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ScribTheme.secondary),
                  minHeight: 3,
                ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _entryController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: _entryController, curve: Curves.easeOut)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isFailed
                            ? ScribTheme.error.withOpacity(0.12)
                            : ScribTheme.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        isFailed
                            ? Icons.error_outline_rounded
                            : Icons.auto_awesome_rounded,
                        color:
                            isFailed ? ScribTheme.error : ScribTheme.secondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isFailed
                          ? 'Processing failed'
                          : 'Processing your lecture...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ScribTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lecture.title,
                      style: const TextStyle(
                          fontSize: 15, color: ScribTheme.textSecondary),
                    ),
                    const SizedBox(height: 40),

                    _ProcessingStep(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Upload audio',
                      subtitle: 'Sending your recording to our servers',
                      status: _stepStatus(lecture, 0),
                      uploadProgress: lecture.uploadProgress,
                    ),
                    const SizedBox(height: 10),
                    _ProcessingStep(
                      icon: Icons.record_voice_over_outlined,
                      title: 'Transcribe speech',
                      subtitle: 'Converting audio to text',
                      status: _stepStatus(lecture, 1),
                    ),
                    const SizedBox(height: 10),
                    _ProcessingStep(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Generate notes',
                      subtitle: 'Summaries, flashcards & key points',
                      status: _stepStatus(lecture, 2),
                    ),

                    const SizedBox(height: 28),

                    if (!isFailed) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: ScribTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: ScribTheme.textSecondary, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                _estimatedTime(lecture),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: ScribTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.popUntil(context, (r) => r.isFirst),
                          child: const Text('Go to Dashboard',
                              style: TextStyle(color: ScribTheme.primary)),
                        ),
                      ),
                    ],

                    if (isFailed) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ScribTheme.error.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: ScribTheme.error.withOpacity(0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: ScribTheme.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lecture.errorMessage ?? 'Unknown error',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: ScribTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                provider.deleteLecture(lecture.id);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ScribTheme.error,
                                side: BorderSide(
                                    color: ScribTheme.error.withOpacity(0.4)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                setState(() => _navigated = false);
                                provider.retryLecture(lecture.id);
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ScribTheme.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _StepStatus _stepStatus(Lecture lecture, int step) {
    switch (lecture.status) {
      case LectureStatus.uploading:
        return step == 0 ? _StepStatus.active : _StepStatus.pending;
      case LectureStatus.transcribing:
        if (step == 0) return _StepStatus.done;
        return step == 1 ? _StepStatus.active : _StepStatus.pending;
      case LectureStatus.generatingNotes:
        if (step < 2) return _StepStatus.done;
        return _StepStatus.active;
      case LectureStatus.completed:
        return _StepStatus.done;
      case LectureStatus.failed:
        return step == 0 ? _StepStatus.failed : _StepStatus.pending;
      default:
        return _StepStatus.pending;
    }
  }

  String _estimatedTime(Lecture lecture) {
    return switch (lecture.status) {
      LectureStatus.uploading => 'Uploading — usually a few seconds',
      LectureStatus.transcribing => 'Transcribing — ~20–40 seconds',
      LectureStatus.generatingNotes => 'Almost done — generating notes',
      _ => 'Estimated ~30 seconds total',
    };
  }
}

// ─── Step Status & Widget ─────────────────────────────────────────────────────

enum _StepStatus { pending, active, done, failed }

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    this.uploadProgress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _StepStatus status;
  final double? uploadProgress;

  @override
  Widget build(BuildContext context) {
    final Color iconBg;
    final Color iconColor;
    final Widget trailing;

    switch (status) {
      case _StepStatus.pending:
        iconBg = ScribTheme.surfaceVariant;
        iconColor = ScribTheme.textSecondary;
        trailing = const SizedBox(width: 22);
      case _StepStatus.active:
        iconBg = ScribTheme.primary.withOpacity(0.14);
        iconColor = ScribTheme.primary;
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: ScribTheme.primary),
        );
      case _StepStatus.done:
        iconBg = ScribTheme.secondary.withOpacity(0.14);
        iconColor = ScribTheme.secondary;
        trailing = const Icon(Icons.check_circle_rounded,
            color: ScribTheme.secondary, size: 22);
      case _StepStatus.failed:
        iconBg = ScribTheme.error.withOpacity(0.12);
        iconColor = ScribTheme.error;
        trailing =
            const Icon(Icons.cancel_rounded, color: ScribTheme.error, size: 22);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == _StepStatus.active
            ? ScribTheme.surface
            : ScribTheme.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == _StepStatus.active
              ? ScribTheme.primary.withOpacity(0.25)
              : ScribTheme.surfaceVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == _StepStatus.pending
                            ? ScribTheme.textSecondary
                            : ScribTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: ScribTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
          if (status == _StepStatus.active &&
              uploadProgress != null &&
              uploadProgress! > 0.0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: ScribTheme.surfaceVariant,
                color: ScribTheme.primary,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
