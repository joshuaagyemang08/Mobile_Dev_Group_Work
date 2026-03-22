// lib/screens/recording_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/lecture_provider.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController(text: 'Lecture');
  final _subjectController = TextEditingController();

  bool _hasStarted = false;
  bool _isPaused = false;
  Duration _elapsed = Duration.zero;
  StreamSubscription<Duration>? _durationSub;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    _durationSub?.cancel();
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final provider = context.read<LectureProvider>();
    await provider.startRecording(
      title: _titleController.text.trim().isEmpty
          ? 'Lecture'
          : _titleController.text.trim(),
      subject: _subjectController.text.trim().isEmpty
          ? null
          : _subjectController.text.trim(),
    );

    _durationSub = provider.recordingDurationStream.listen((d) {
      if (mounted) setState(() => _elapsed = d);
    });

    setState(() => _hasStarted = true);
  }

  Future<void> _pauseResume() async {
    final provider = context.read<LectureProvider>();
    if (_isPaused) {
      await provider.resumeRecording();
      _pulseController.repeat(reverse: true);
    } else {
      await provider.pauseRecording();
      _pulseController.stop();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopAndProcess() async {
    final confirmed = await _showStopDialog();
    if (!confirmed) return;

    await context.read<LectureProvider>().stopRecordingAndProcess(
          title: _titleController.text.trim().isEmpty
              ? 'Lecture'
              : _titleController.text.trim(),
          subject: _subjectController.text.trim().isEmpty
              ? null
              : _subjectController.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '✅ Recording saved! Your notes will be ready shortly.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _showStopDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: ScribTheme.surface,
            title: const Text('Stop Recording?'),
            content: const Text(
                'The audio will be uploaded and your notes will be generated automatically.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Stop & Process'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Lecture'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_hasStarted) {
              // warn user that recording will be lost
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: ScribTheme.surface,
                  title: const Text('Discard recording?'),
                  content: const Text(
                      'If you go back now, the current recording will be lost.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Stay')),
                    FilledButton(
                        onPressed: () {
                          Navigator.pop(context); // close dialog
                          Navigator.pop(context); // go back
                        },
                        child: const Text('Discard')),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Title & Subject inputs (disabled once recording starts) ──
            TextField(
              controller: _titleController,
              enabled: !_hasStarted,
              decoration: _inputDecoration('Lecture Title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              enabled: !_hasStarted,
              decoration: _inputDecoration('Subject (optional)'),
            ),

            const Spacer(),

            // ── Timer display ──
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Opacity(
                opacity: _hasStarted && !_isPaused
                    ? 0.6 + _pulseController.value * 0.4
                    : 1.0,
                child: child,
              ),
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hasStarted && !_isPaused
                          ? ScribTheme.recording
                          : ScribTheme.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDuration(_elapsed),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                      color: ScribTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasStarted
                        ? (_isPaused ? 'Paused' : 'Recording...')
                        : 'Ready to record',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Control buttons ──
            if (!_hasStarted)
              _RecordButton(
                onPressed: _startRecording,
                label: 'Start Recording',
                color: ScribTheme.recording,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconActionButton(
                    icon: _isPaused ? Icons.play_arrow : Icons.pause,
                    label: _isPaused ? 'Resume' : 'Pause',
                    onPressed: _pauseResume,
                  ),
                  const SizedBox(width: 24),
                  _RecordButton(
                    onPressed: _stopAndProcess,
                    label: 'Stop',
                    color: ScribTheme.error,
                    icon: Icons.stop,
                  ),
                ],
              ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: ScribTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.onPressed,
    required this.label,
    required this.color,
    this.icon = Icons.mic,
  });
  final VoidCallback onPressed;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 24)
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton(
      {required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          IconButton.outlined(
            icon: Icon(icon),
            iconSize: 28,
            onPressed: onPressed,
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}