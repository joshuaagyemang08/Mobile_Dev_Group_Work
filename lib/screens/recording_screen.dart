// lib/screens/recording_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../providers/lecture_provider.dart';
import 'processing_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();

  bool _hasStarted = false;
  bool _isPaused = false;
  bool _isStopping = false;
  Duration _elapsed = Duration.zero;
  StreamSubscription<Duration>? _durationSub;

  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void initState() {
    super.initState();
    _loadDefaultTitle();
  }

  Future<void> _loadDefaultTitle() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('lecture_count') ?? 0) + 1;
    if (mounted) {
      _titleController.text = 'Lecture $count';
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    _durationSub?.cancel();
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

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

    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('lecture_count') ?? 0) + 1;
    await prefs.setInt('lecture_count', count);

    _durationSub = provider.recordingDurationStream.listen((d) {
      if (mounted) setState(() => _elapsed = d);
    });

    _waveController.repeat();
    setState(() {
      _hasStarted = true;
      _isPaused = false;
    });
  }

  Future<void> _pauseResume() async {
    final provider = context.read<LectureProvider>();
    if (_isPaused) {
      await provider.resumeRecording();
      _waveController.repeat();
    } else {
      await provider.pauseRecording();
      _waveController.stop();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopAndProcess() async {
    final confirmed = await _showStopDialog();
    if (!confirmed || !mounted) return;

    setState(() => _isStopping = true);
    _waveController.stop();

    final lectureId =
        await context.read<LectureProvider>().stopRecordingAndProcess(
              title: _titleController.text.trim().isEmpty
                  ? 'Lecture'
                  : _titleController.text.trim(),
              subject: _subjectController.text.trim().isEmpty
                  ? null
                  : _subjectController.text.trim(),
            );

    if (!mounted) return;

    if (lectureId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(lectureId: lectureId),
        ),
      );
    } else {
      setState(() => _isStopping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save recording')),
      );
    }
  }

  Future<bool> _showStopDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black54,
          builder: (_) => Dialog(
            backgroundColor: ScribTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: ScribTheme.error.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stop_rounded,
                        color: ScribTheme.error, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stop Recording?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ScribTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your audio will be uploaded and notes generated automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: ScribTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: ScribTheme.surfaceVariant),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Keep Recording',
                              style: TextStyle(
                                  color: ScribTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: ScribTheme.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Stop & Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showDiscardDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: ScribTheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Discard recording?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ScribTheme.onSurface),
              ),
              const SizedBox(height: 8),
              const Text(
                'The current recording will be lost.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: ScribTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: ScribTheme.surfaceVariant),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Stay',
                          style: TextStyle(
                              color: ScribTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: ScribTheme.error,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasStarted,
      onPopInvoked: (didPop) {
        if (!didPop && _hasStarted) _showDiscardDialog();
      },
      child: Scaffold(
        backgroundColor: ScribTheme.background,
        body: Stack(
          children: [
            // Ambient background glow
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.4),
                      radius: 0.9,
                      colors: [
                        ScribTheme.primary.withOpacity(
                            (_hasStarted ? 0.07 : 0.05) +
                                _glowController.value * 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeController,
                child: _isStopping
                    ? _buildStoppingOverlay()
                    : _hasStarted
                        ? _buildRecordingUI()
                        : _buildSetupUI(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupUI() {
    return Column(
      children: [
        _buildTopBar('New Recording', showClose: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'What are you recording?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ScribTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Give your lecture a title so you can find it later.',
                  style: TextStyle(
                      fontSize: 14, color: ScribTheme.textSecondary),
                ),
                const SizedBox(height: 28),
                _buildInputField(
                  controller: _titleController,
                  hint: 'Lecture title',
                  icon: Icons.edit_note_rounded,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _subjectController,
                  hint: 'Subject (optional)',
                  icon: Icons.school_outlined,
                  maxLength: 50,
                ),
                const Spacer(),
                // Mic button
                Center(
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, __) {
                      final g = _glowController.value;
                      return Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 136 + g * 8,
                                height: 136 + g * 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ScribTheme.primary
                                        .withOpacity(0.08 + g * 0.07),
                                  ),
                                ),
                              ),
                              Container(
                                width: 112 + g * 4,
                                height: 112 + g * 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ScribTheme.primary
                                        .withOpacity(0.12 + g * 0.08),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _startRecording,
                                child: Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        ScribTheme.primary,
                                        Color(0xFF7B6FF0),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ScribTheme.primary
                                            .withOpacity(0.35 + g * 0.15),
                                        blurRadius: 28 + g * 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.mic_rounded,
                                      color: Colors.white, size: 36),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Tap to start recording',
                            style: TextStyle(
                                fontSize: 14,
                                color: ScribTheme.textSecondary),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      children: [
        // Top bar with rec pill
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close,
                    color: ScribTheme.textSecondary),
                onPressed: _showDiscardDialog,
              ),
              Expanded(
                child: Text(
                  _titleController.text.isEmpty
                      ? 'Recording...'
                      : _titleController.text,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ScribTheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ScribTheme.recording.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: ScribTheme.recording.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: ScribTheme.recording,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isPaused ? 'PAUSED' : 'REC',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ScribTheme.recording,
                          letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Waveform visualizer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) => SizedBox(
              height: 88,
              width: double.infinity,
              child: CustomPaint(
                painter: _WaveformPainter(
                  animValue: _waveController.value,
                  isActive: !_isPaused,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 44),

        // Timer
        Text(
          _formatDuration(_elapsed),
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w200,
            letterSpacing: 4,
            color: ScribTheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),
        Text(
          _isPaused ? 'Paused' : 'Recording...',
          style: const TextStyle(
              fontSize: 14, color: ScribTheme.textSecondary),
        ),

        const Spacer(),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: _isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              label: _isPaused ? 'Resume' : 'Pause',
              color: ScribTheme.textSecondary,
              size: 58,
              onTap: _pauseResume,
            ),
            const SizedBox(width: 36),
            _ControlButton(
              icon: Icons.stop_rounded,
              label: 'Stop',
              color: ScribTheme.error,
              size: 74,
              onTap: _stopAndProcess,
              glowColor: ScribTheme.error,
            ),
          ],
        ),

        const SizedBox(height: 56),
      ],
    );
  }

  Widget _buildStoppingOverlay() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              color: ScribTheme.primary, strokeWidth: 2),
          SizedBox(height: 20),
          Text('Saving recording...',
              style: TextStyle(
                  fontSize: 15, color: ScribTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTopBar(String title, {bool showClose = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          if (showClose)
            IconButton(
              icon: const Icon(Icons.close,
                  color: ScribTheme.textSecondary),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ScribTheme.onSurface),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLength = 100,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ScribTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ScribTheme.surfaceVariant),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        // Block HTML/injection characters: < > { } ; \ "
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'[<>{};\\"]')),
        ],
        style:
            const TextStyle(color: ScribTheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: ScribTheme.textSecondary, fontSize: 15),
          prefixIcon:
              Icon(icon, color: ScribTheme.textSecondary, size: 20),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ─── Waveform Painter ─────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double animValue;
  final bool isActive;

  const _WaveformPainter(
      {required this.animValue, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 36;
    const gap = 3.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;

    for (int i = 0; i < barCount; i++) {
      double heightFraction;
      if (!isActive) {
        heightFraction =
            0.06 + (math.sin(i * 0.8) * 0.5 + 0.5) * 0.14;
      } else {
        final phase = i / barCount * math.pi * 4;
        final w1 = math.sin(animValue * math.pi * 2 + phase);
        final w2 =
            math.sin(animValue * math.pi * 5 + phase * 1.4) * 0.4;
        heightFraction = ((w1 + w2 + 1.4) / 2.8).clamp(0.05, 1.0);
      }

      final barHeight = size.height * heightFraction;
      final x = i * (barWidth + gap);
      final y = (size.height - barHeight) / 2;
      final opacity =
          isActive ? (0.4 + heightFraction * 0.6) : 0.22;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(2),
        ),
        Paint()
          ..color = ScribTheme.primary.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.animValue != animValue || old.isActive != isActive;
}

// ─── Control Button ───────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
    this.glowColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border:
                  Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: glowColor != null
                  ? [
                      BoxShadow(
                        color: glowColor!.withOpacity(0.22),
                        blurRadius: 20,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Icon(icon, color: color, size: size * 0.46),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: ScribTheme.textSecondary)),
      ],
    );
  }
}
