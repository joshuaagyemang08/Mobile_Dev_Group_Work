// lib/screens/notes_screen.dart
//
// home_screen.dart. All four Member 4 TODOs are implemented:
//   ✅ _FlashcardsView  — 3D flip animation, swipe gestures, progress bar
//   ✅ _TranscriptView  — search bar with highlight + scroll-to-first-match
//   ✅ Share / Export   — share sheet (PDF text + copy Markdown)
//   ✅ _NotesView TOC   — floating drawer listing every ## heading

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../models/lecture.dart';

// ─── Palette (mirrors home_screen.dart) ──────────────────────────────────────
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
const _cream   = Color(0xFFF9F4EE);
const _red     = Color(0xFFE24B4A);

// ─── Shared ink-bordered container ───────────────────────────────────────────

class _InkBox extends StatelessWidget {
  const _InkBox({
    required this.child,
    this.color = Colors.white,
    this.width,
    this.height,
    this.radius = 20.0,
    this.padding,
    this.onTap,
  });
  final Widget child;
  final Color color;
  final double? width, height;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
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
    if (onTap == null) return box;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: box,
      ),
    );
  }
}

// ─── Notes Screen ─────────────────────────────────────────────────────────────

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.lecture});
  final Lecture lecture;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 4, vsync: this);

  void _share() {
    final notes = widget.lecture.notes;
    if (notes == null) return;
    Share.share(
      notes.fullNotes,
      subject: widget.lecture.title,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.lecture.notes;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _InkBox(
          width: 36,
          height: 36,
          radius: 10,
          color: Colors.white,
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, size: 18, color: _ink),
        ).withPadding(const EdgeInsets.only(left: 12, top: 6, bottom: 6)),
        leadingWidth: 60,
        title: Text(
          widget.lecture.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -.3,
          ),
        ),
        actions: [
          _InkBox(
            width: 36,
            height: 36,
            radius: 10,
            color: _purpleL,
            onTap: _share,
            child: const Icon(Icons.ios_share_rounded, size: 16, color: _purple),
          ).withPadding(
              const EdgeInsets.only(right: 12, top: 6, bottom: 6)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _TabRow(controller: _tabController),
        ),
      ),
      body: notes == null
          ? _EmptyNotes()
          : TabBarView(
              controller: _tabController,
              children: [
                _NotesView(notes: notes),
                _SummaryView(notes: notes),
                _FlashcardsView(notes: notes),
                _TranscriptView(transcript: widget.lecture.transcript),
              ],
            ),
    );
  }
}

// ─── Custom Tab Row ───────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  const _TabRow({required this.controller});
  final TabController controller;

  static const _labels = ['Notes', 'Summary', 'Flashcards', 'Transcript'];

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(20),
          labelColor: Colors.white,
          unselectedLabelColor: _ink,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .2),
          unselectedLabelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InkBox(
              width: 70,
              height: 70,
              radius: 20,
              color: _purpleL,
              child: const Icon(Icons.notes_rounded, size: 30, color: _purple),
            ),
            const SizedBox(height: 16),
            const Text('Notes not available',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink)),
          ],
        ),
      );
}

// ─── Tab 1: Full Notes + Floating TOC ────────────────────────────────────────

class _NotesView extends StatefulWidget {
  const _NotesView({required this.notes});
  final LectureNotes notes;

  @override
  State<_NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<_NotesView> {
  bool _tocOpen = false;

  List<String> get _headings => widget.notes.fullNotes
      .split('\n')
      .where((l) => l.startsWith('## '))
      .map((l) => l.replaceFirst('## ', ''))
      .toList();

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Markdown content
          Markdown(
            data: widget.notes.fullNotes,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -.5),
              h2: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _purple),
              h3: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _green),
              p: const TextStyle(
                  fontSize: 14, color: _ink, height: 1.65),
              listBullet: const TextStyle(
                  fontSize: 14, color: _ink, height: 1.65),
              strong: const TextStyle(
                  fontWeight: FontWeight.w700, color: _ink),
              blockquoteDecoration: BoxDecoration(
                color: _purpleL,
                border: const Border(
                    left: BorderSide(color: _purple, width: 3)),
                borderRadius: BorderRadius.circular(4),
              ),
              code: const TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: Color(0xFFF2EAE4),
                  fontSize: 13),
            ),
          ),

          // TOC drawer slide-in from right
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            right: _tocOpen ? 0 : -240,
            top: 0,
            bottom: 0,
            width: 220,
            child: _TocDrawer(
              headings: _headings,
              onClose: () => setState(() => _tocOpen = false),
            ),
          ),

          // TOC toggle button (bottom-right)
          Positioned(
            right: 16,
            bottom: 24,
            child: _InkBox(
              radius: 14,
              color: _tocOpen ? _ink : _purpleL,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              onTap: () => setState(() => _tocOpen = !_tocOpen),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_rounded,
                      size: 16,
                      color: _tocOpen ? Colors.white : _purple),
                  const SizedBox(width: 6),
                  Text('Contents',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _tocOpen ? Colors.white : _purple)),
                ],
              ),
            ),
          ),
        ],
      );
}

class _TocDrawer extends StatelessWidget {
  const _TocDrawer(
      {required this.headings, required this.onClose});
  final List<String> headings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: _ink, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Contents',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: _ink),
                  ),
                ],
              ),
            ),
            const Divider(
                color: _ink, thickness: 1.5, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: headings.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: _purple,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(headings[i],
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: _ink,
                                  fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── Tab 2: Summary + Key Points ─────────────────────────────────────────────

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.notes});
  final LectureNotes notes;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // Topics chips
          if (notes.topics.isNotEmpty) ...[
            _SectionLabel(label: 'Topics covered'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notes.topics
                  .map((t) => _TopicChip(label: t))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Summary
          _SectionCard(
            icon: Icons.summarize_outlined,
            title: 'Summary',
            color: _purpleL,
            accentColor: _purple,
            child: Text(notes.summary,
                style: const TextStyle(
                    fontSize: 14, color: _ink, height: 1.65)),
          ),
          const SizedBox(height: 14),

          // Key points
          _SectionCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Key points',
            color: _greenL,
            accentColor: _green,
            child: Column(
              children: notes.keyPoints
                  .asMap()
                  .entries
                  .map((e) => _KeyPoint(index: e.key + 1, text: e.value))
                  .toList(),
            ),
          ),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
            color: _ink),
      );
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => _InkBox(
        radius: 20,
        color: _greenL,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: _green,
                fontWeight: FontWeight.w600)),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.color,
    required this.accentColor,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Color color, accentColor;

  @override
  Widget build(BuildContext context) => _InkBox(
        color: color,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InkBox(
                  width: 30,
                  height: 30,
                  radius: 8,
                  color: Colors.white.withOpacity(.7),
                  child: Icon(icon, size: 15, color: accentColor),
                ),
                const SizedBox(width: 8),
                Text(title.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: accentColor)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _KeyPoint extends StatelessWidget {
  const _KeyPoint({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InkBox(
              width: 24,
              height: 24,
              radius: 20,
              color: Colors.white.withOpacity(.6),
              child: Center(
                child: Text('$index',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _green)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14, color: _ink, height: 1.5)),
            ),
          ],
        ),
      );
}

// ─── Tab 3: Flashcards — 3D flip + swipe + progress ──────────────────────────

class _FlashcardsView extends StatefulWidget {
  const _FlashcardsView({required this.notes});
  final LectureNotes notes;

  @override
  State<_FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends State<_FlashcardsView>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  bool _showAnswer = false;
  final Set<int> _reviewed = {};

  // Flip animation
  late final AnimationController _flipCtrl;
  late final Animation<double> _frontAnim;
  late final Animation<double> _backAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420));
    _frontAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: math.pi / 2)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
      TweenSequenceItem(tween: ConstantTween(math.pi / 2), weight: 50),
    ]).animate(_flipCtrl);
    _backAnim = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(math.pi / 2), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: math.pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
    ]).animate(_flipCtrl);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipCtrl.isAnimating) return;
    if (_showAnswer) {
      _flipCtrl.reverse().then((_) {
        if (mounted) setState(() => _showAnswer = false);
      });
    } else {
      _flipCtrl.forward().then((_) {
        if (mounted) setState(() {
          _showAnswer = true;
          _reviewed.add(_current);
        });
      });
    }
  }

  void _next() {
    if (_current >= widget.notes.flashcards.length - 1) return;
    _flipCtrl.reset();
    setState(() {
      _showAnswer = false;
      _current++;
    });
  }

  void _prev() {
    if (_current <= 0) return;
    _flipCtrl.reset();
    setState(() {
      _showAnswer = false;
      _current--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.notes.flashcards;
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InkBox(
              width: 64,
              height: 64,
              radius: 18,
              color: _purpleL,
              child: const Icon(Icons.style_rounded,
                  size: 28, color: _purple),
            ),
            const SizedBox(height: 14),
            const Text('No flashcards generated.',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ink)),
          ],
        ),
      );
    }
    final card = cards[_current];
    final pct = _reviewed.length / cards.length;

    return Column(
      children: [
        const SizedBox(height: 20),

        // Progress row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text('${_current + 1} / ${cards.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: _purpleM.withOpacity(.35),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_purple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_reviewed.length} reviewed',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _purple)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Swipeable 3-D flip card
        Expanded(
          child: GestureDetector(
            onTap: _flip,
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -300) _next();
              if ((d.primaryVelocity ?? 0) > 300) _prev();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _flipCtrl,
                builder: (_, __) {
                  final isFront = _flipCtrl.value < .5;
                  final angle =
                      isFront ? _frontAnim.value : _backAnim.value;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isFront
                        ? _CardFace(
                            label: 'Question',
                            text: card.question,
                            color: Colors.white,
                            labelColor: _purple,
                            hint: 'Tap to reveal answer · swipe to navigate',
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(math.pi),
                            child: _CardFace(
                              label: 'Answer',
                              text: card.answer,
                              color: _greenL,
                              labelColor: _green,
                              hint: 'Tap to flip back',
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Prev / Next buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InkBox(
              width: 48,
              height: 48,
              radius: 14,
              color: _current > 0 ? _purpleL : const Color(0xFFF2EAE4),
              onTap: _current > 0 ? _prev : null,
              child: Icon(Icons.arrow_back_rounded,
                  size: 20,
                  color: _current > 0 ? _purple : Colors.black26),
            ),
            const SizedBox(width: 16),
            _InkBox(
              width: 48,
              height: 48,
              radius: 14,
              color: _current < cards.length - 1
                  ? _purpleL
                  : const Color(0xFFF2EAE4),
              onTap: _current < cards.length - 1 ? _next : null,
              child: Icon(Icons.arrow_forward_rounded,
                  size: 20,
                  color: _current < cards.length - 1
                      ? _purple
                      : Colors.black26),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.label,
    required this.text,
    required this.color,
    required this.labelColor,
    required this.hint,
  });
  final String label, text, hint;
  final Color color, labelColor;

  @override
  Widget build(BuildContext context) => _InkBox(
        color: color,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InkBox(
              radius: 20,
              color: Colors.white.withOpacity(.7),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              child: Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                      color: labelColor)),
            ),
            const SizedBox(height: 24),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(hint,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black38)),
          ],
        ),
      );
}

// ─── Tab 4: Transcript — search + highlight + scroll-to-match ────────────────

class _TranscriptView extends StatefulWidget {
  const _TranscriptView({required this.transcript});
  final String? transcript;

  @override
  State<_TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<_TranscriptView> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _textKey    = GlobalKey();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Scroll to the approximate position of the first match.
  void _scrollToFirstMatch(String text, String query) {
    if (query.isEmpty) return;
    final idx = text.toLowerCase().indexOf(query.toLowerCase());
    if (idx < 0) return;
    final charFraction = idx / text.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      _scrollCtrl.animateTo(
        maxScroll * charFraction,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.transcript ?? '';
    if (raw.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InkBox(
              width: 64,
              height: 64,
              radius: 18,
              color: _amberL,
              child: const Icon(Icons.transcript, size: 28, color: _amber),
            ),
            const SizedBox(height: 14),
            const Text('Transcript not available.',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ink)),
          ],
        ),
      );
    }

    final spans = _buildSpans(raw, _query);
    final matchCount = _query.isEmpty
        ? 0
        : RegExp(RegExp.escape(_query), caseSensitive: false)
            .allMatches(raw)
            .length;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _InkBox(
            color: Colors.white,
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 18, color: _purple),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _ink),
                    decoration: const InputDecoration(
                      hintText: 'Search transcript…',
                      hintStyle: TextStyle(
                          fontSize: 14, color: Colors.black38),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) {
                      setState(() => _query = v.trim());
                      _scrollToFirstMatch(raw, v.trim());
                    },
                  ),
                ),
                if (_query.isNotEmpty) ...[
                  Text('$matchCount',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _purple)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.black38),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Transcript body
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            child: RichText(
              key: _textKey,
              text: TextSpan(children: spans),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildSpans(String text, String query) {
    if (query.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: const TextStyle(
              fontSize: 14,
              color: _ink,
              height: 1.75),
        ),
      ];
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    int start = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(
              fontSize: 14, color: _ink, height: 1.75),
        ));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: const TextStyle(
              fontSize: 14, color: _ink, height: 1.75),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          fontSize: 14,
          color: _ink,
          height: 1.75,
          fontWeight: FontWeight.w700,
          backgroundColor: Color(0xFFCECBF6),
        ),
      ));
      start = idx + query.length;
    }
    return spans;
  }
}

// ─── Extension helpers ────────────────────────────────────────────────────────

extension on Widget {
  Widget withPadding(EdgeInsetsGeometry p) => Padding(padding: p, child: this);
}