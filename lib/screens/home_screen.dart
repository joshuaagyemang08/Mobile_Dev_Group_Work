// lib/screens/home_screen.dart
//
// 
//   • Ink-bordered cards (_InkBox)
//   • Animated waveform bars (live recording)
//   • Animated ring/donut (notes ready)
//   • Count-up number animation
//   • Heatmap cells revealed on load
//   • Shimmer/indeterminate progress bars
//

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/lecture.dart';
import '../providers/lecture_provider.dart';
import 'recording_screen.dart';
import 'notes_screen.dart';

// ─── Color constants ──────────────────────────────────────────────────────────
const _ink     = Color(0xFF1A1228);
const _purple  = Color(0xFF6C63E9);
const _purpleL = Color(0xFFEEEDFE);
const _purpleM = Color(0xFFCECBF6);
const _green   = Color(0xFF1D9E75);
const _greenL  = Color(0xFFE1F5EE);
const _amber   = Color(0xFFBA7517);
const _amberL  = Color(0xFFFAEEDA);
const _pink    = Color(0xFF993556);
const _pinkL   = Color(0xFFFBEAF0);
const _pinkM   = Color(0xFFED93B1);
const _cream   = Color(0xFFF9F4EE);
const _red     = Color(0xFFE24B4A);

// ─── Shared ink-bordered card container ──────────────────────────────────────

class _InkBox extends StatelessWidget {
  const _InkBox({
    required this.child,
    this.color = Colors.white,
    this.width,
    this.height,
    this.radius = 20.0,
    this.padding,
  });
  final Widget child;
  final Color color;
  final double? width, height;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _ink, width: 2),
        ),
        child: child,
      );
}


// ─── Home Screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LectureProvider>().loadLectures();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _cream,
        body: Consumer<LectureProvider>(
          builder: (context, provider, _) {
            final lectures = provider.lectures;
            return CustomScrollView(
              slivers: [
                _SliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverToBoxAdapter(
                    child: lectures.isEmpty
                        ? const _EmptyState()
                        : _Dashboard(lectures: lectures),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordingScreen()),
          ),
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          icon: const Icon(Icons.mic_none_rounded, size: 20),
          label: const Text('Record',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2)),
        ),
      );
}

// ─── Sliver App Bar ───────────────────────────────────────────────────────────

class _SliverAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 20),
            child: Row(
              children: [
                _InkBox(
                  width: 36,
                  height: 36,
                  radius: 10,
                  color: _purpleL,
                  child: const Center(
                    child: Text('✏️', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Scrib',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -1)),
                const Spacer(),
                _InkBox(
                  width: 36,
                  height: 36,
                  radius: 10,
                  color: Colors.white,
                  child: const Icon(Icons.tune_rounded, size: 18, color: _ink),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InkBox(
                width: 80,
                height: 80,
                radius: 24,
                color: _purpleL,
                child: const Icon(Icons.mic_none_rounded,
                    size: 36, color: _purple),
              ),
              const SizedBox(height: 20),
              const Text('No lectures yet',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
              const SizedBox(height: 8),
              const Text('Tap below to record your first lecture',
                  style: TextStyle(fontSize: 13, color: _purple)),
            ],
          ),
        ),
      );
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.lectures});
  final List<Lecture> lectures;

  @override
  Widget build(BuildContext context) {
    final completed =
        lectures.where((l) => l.status == LectureStatus.completed).length;
    final totalMins =
        lectures.fold(Duration.zero, (a, l) => a + l.duration).inMinutes;
    final processing = lectures
        .where((l) =>
            l.status != LectureStatus.completed &&
            l.status != LectureStatus.failed)
        .toList();
    final live = processing.isNotEmpty ? processing.first : null;

    return Column(
      children: [
        // Row 1 ─ count-up stat + live recording (or hours)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CountUpCard(
                  label: 'Total lectures',
                  value: lectures.length,
                  color: _purpleL,
                  accentColor: _purple,
                  chips: const ['Biology', 'Physics', 'Maths'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: live != null
                    ? _LiveRecordingCard(lecture: live)
                    : _HoursCard(totalMins: totalMins),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 2 ─ ring progress + hours
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _RingProgressCard(
                    ready: completed, total: lectures.length),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _HoursCard(totalMins: totalMins),
                    if (processing.length > 1) ...[
                      const SizedBox(height: 12),
                      _ProcessingCard(
                          lectures: processing.skip(1).toList()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 3 ─ activity heatmap
        _HeatmapCard(lectures: lectures),
        const SizedBox(height: 12),

        // Row 4 ─ completed lecture list
        ...lectures
            .where((l) => l.status == LectureStatus.completed)
            .take(4)
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LectureCard(lecture: l),
                )),
      ],
    );
  }
}

// ─── Count-Up Card ────────────────────────────────────────────────────────────

class _CountUpCard extends StatefulWidget {
  const _CountUpCard({
    required this.label,
    required this.value,
    required this.color,
    required this.accentColor,
    required this.chips,
  });
  final String label;
  final int value;
  final Color color, accentColor;
  final List<String> chips;

  @override
  State<_CountUpCard> createState() => _CountUpCardState();
}

class _CountUpCardState extends State<_CountUpCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InkBox(
        color: widget.color,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: widget.accentColor)),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Text(
                '${(_anim.value * widget.value).round()}',
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1,
                    letterSpacing: -2),
              ),
            ),
            const SizedBox(height: 4),
            Text('this semester',
                style: TextStyle(
                    fontSize: 12,
                    color: widget.accentColor.withOpacity(.75))),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.chips
                  .map((c) => _InkBox(
                        color: Colors.white.withOpacity(.6),
                        radius: 20,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.accentColor)),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
}

// ─── Live Recording Card ──────────────────────────────────────────────────────

class _LiveRecordingCard extends StatefulWidget {
  const _LiveRecordingCard({required this.lecture});
  final Lecture lecture;

  @override
  State<_LiveRecordingCard> createState() => _LiveRecordingCardState();
}

class _LiveRecordingCardState extends State<_LiveRecordingCard>
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final List<AnimationController> _bars;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _bars = List.generate(12, (_) {
      return AnimationController(
        vsync: this,
        duration:
            Duration(milliseconds: 600 + _rng.nextInt(700)),
      )..repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _blink.dispose();
    for (final b in _bars) b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InkBox(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with blinking dot
            Row(
              children: [
                FadeTransition(
                  opacity: _blink,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: _red, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 7),
                const Text('LIVE RECORDING',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: _ink)),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.lecture.title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),

            // Animated waveform bars
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  12,
                  (i) => Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 1.5),
                      child: AnimatedBuilder(
                        animation: _bars[i],
                        builder: (_, __) {
                          final h = 8.0 + _bars[i].value * 36;
                          return Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: h,
                              decoration: BoxDecoration(
                                color: _purple,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('00:42:17',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
                _InkBox(
                  radius: 20,
                  color: const Color(0xFFFCEBEB),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  child: const Text('recording',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA32D2D))),
                ),
              ],
            ),
          ],
        ),
      );
}

// ─── Ring Progress Card ───────────────────────────────────────────────────────

class _RingProgressCard extends StatefulWidget {
  const _RingProgressCard({required this.ready, required this.total});
  final int ready, total;

  @override
  State<_RingProgressCard> createState() => _RingProgressCardState();
}

class _RingProgressCardState extends State<_RingProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct =
        widget.total == 0 ? 0.0 : widget.ready / widget.total;
    return _InkBox(
      color: _greenL,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('NOTES READY',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: _green)),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: _anim.value * pct,
                  trackColor: const Color(0xFF9FE1CB),
                  fillColor: _green,
                  strokeWidth: 13,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${widget.ready}',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              height: 1)),
                      Text('of ${widget.total}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _green)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Completion',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => Text(
                  '${(_anim.value * pct * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _anim.value * pct,
                minHeight: 6,
                backgroundColor: const Color(0xFF9FE1CB),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(_green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the donut ring
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });
  final double progress;
  final Color trackColor, fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = fillColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress;
}

// ─── Hours Card ───────────────────────────────────────────────────────────────

class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.totalMins});
  final int totalMins;

  @override
  Widget build(BuildContext context) {
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    return _InkBox(
      color: _amberL,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOURS RECORDED',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .6,
                  color: _amber)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$h',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -2,
                      height: 1)),
              const Text('h ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _amber)),
              Text('$m',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -1,
                      height: 1)),
              const Text('m',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _amber)),
            ],
          ),
          const Text('past 30 days',
              style: TextStyle(fontSize: 12, color: _amber)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ZoneStat(
                  dot: _purple,
                  label: 'Lectures',
                  value: '${(h * 0.75).round()}h'),
              Container(
                width: 1,
                height: 36,
                color: _ink.withOpacity(.12),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _ZoneStat(
                  dot: _green,
                  label: 'Seminars',
                  value: '${(h * 0.25).round()}h'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneStat extends StatelessWidget {
  const _ZoneStat(
      {required this.dot, required this.label, required this.value});
  final Color dot;
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(color: _ink, width: 1.5),
                ),
              ),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
        ],
      );
}

// ─── Processing Card ──────────────────────────────────────────────────────────

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard({required this.lectures});
  final List<Lecture> lectures;

  @override
  Widget build(BuildContext context) => _InkBox(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PROCESSING',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: _ink)),
            const SizedBox(height: 12),
            ...lectures.take(2).map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ProcessingRow(lecture: l),
                )),
          ],
        ),
      );
}

class _ProcessingRow extends StatelessWidget {
  const _ProcessingRow({required this.lecture});
  final Lecture lecture;

  @override
  Widget build(BuildContext context) {
    final label = switch (lecture.status) {
      LectureStatus.uploading =>
        'Uploading ${(lecture.uploadProgress * 100).round()}%',
      LectureStatus.transcribing => 'Transcribing…',
      LectureStatus.generatingNotes => 'Generating notes…',
      _ => '',
    };
    final isIndeterminate =
        lecture.status != LectureStatus.uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(lecture.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _purple)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isIndeterminate ? null : lecture.uploadProgress,
            minHeight: 5,
            backgroundColor: _purpleM.withOpacity(.35),
            valueColor:
                const AlwaysStoppedAnimation<Color>(_purple),
          ),
        ),
      ],
    );
  }
}

// ─── Heatmap Card ─────────────────────────────────────────────────────────────

class _HeatmapCard extends StatefulWidget {
  const _HeatmapCard({required this.lectures});
  final List<Lecture> lectures;

  @override
  State<_HeatmapCard> createState() => _HeatmapCardState();
}

class _HeatmapCardState extends State<_HeatmapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<int> _cells;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _cells = List.generate(28, (_) => rng.nextInt(3));
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [_pinkL, _pinkM, _pink];
    const strokes = [
      Color(0xFFD4537E),
      Color(0xFF993556),
      Color(0xFF4B1528),
    ];

    return _InkBox(
      color: _pinkL,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTIVITY CALENDAR',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                      color: _pink)),
              _InkBox(
                radius: 20,
                color: Colors.white.withOpacity(.6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                child: const Text('Apr 2026',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _pink)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final revealed =
                  (_ctrl.value * _cells.length).round();
              return Wrap(
                spacing: 5,
                runSpacing: 5,
                children: List.generate(_cells.length, (i) {
                  final v = i < revealed ? _cells[i] : 0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors[v],
                      borderRadius: BorderRadius.circular(7),
                      border:
                          Border.all(color: strokes[v], width: 1.5),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: strokes[i], width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                          i == 0
                              ? 'none'
                              : i == 1
                                  ? '1 lec'
                                  : '2+ lec',
                          style: const TextStyle(
                              fontSize: 11, color: _pink)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Lecture Card ─────────────────────────────────────────────────────────────

class _LectureCard extends StatelessWidget {
  const _LectureCard({required this.lecture});
  final Lecture lecture;

  @override
  Widget build(BuildContext context) => _InkBox(
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => NotesScreen(lecture: lecture)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _InkBox(
                  width: 44,
                  height: 44,
                  radius: 13,
                  color: _greenL,
                  child: const Icon(Icons.check_rounded,
                      size: 22, color: _green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lecture.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (lecture.subject != null) ...[
                            _InkBox(
                              radius: 20,
                              color: _purpleL,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              child: Text(lecture.subject!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _purple)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${lecture.duration.inMinutes}m · '
                            '${DateFormat('MMM d').format(lecture.recordedAt)}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.black26),
              ],
            ),
          ),
        ),
      );
}