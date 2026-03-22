// lib/screens/notes_screen.dart
//
// ════════════════════════════════════════════════════════════════════════════
// TEAMMATE TASK (Member 4)
// This file is the main deliverable for the UI teammate.
// The skeleton below has three tabs wired up. Your job is to:
//   1. Build out _FlashcardsView with flip-card animation.
//   2. Build out _TranscriptView with search/highlight functionality.
//   3. Add a share/export button (share as PDF or copy Markdown).
//   4. Polish the _NotesView — add a floating table-of-contents drawer.
// Each of those is roughly one commit. See the TODO comments.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/theme.dart';
import '../models/lecture.dart';

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.lecture.notes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lecture.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // TODO (Member 4): wire up share/export
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ScribTheme.primary,
          labelColor: ScribTheme.primary,
          unselectedLabelColor: ScribTheme.textSecondary,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Summary'),
            Tab(text: 'Flashcards'),
            Tab(text: 'Transcript'),
          ],
        ),
      ),
      body: notes == null
          ? const Center(child: Text('Notes not available'))
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

// ─── Tab 1: Full Markdown Notes ───────────────────────────────────────────────

class _NotesView extends StatelessWidget {
  const _NotesView({required this.notes});
  final LectureNotes notes;

  @override
  Widget build(BuildContext context) {
    // TODO (Member 4): Add a floating table-of-contents drawer that lets
    // students jump to any ## heading quickly.
    return Markdown(
      data: notes.fullNotes,
      padding: const EdgeInsets.all(20),
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ScribTheme.onSurface),
        h2: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ScribTheme.primary),
        h3: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: ScribTheme.secondary),
        p: const TextStyle(fontSize: 14, color: ScribTheme.onSurface, height: 1.6),
        listBullet: const TextStyle(fontSize: 14, color: ScribTheme.onSurface, height: 1.6),
        strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        blockquoteDecoration: BoxDecoration(
          color: ScribTheme.primary.withOpacity(0.1),
          border:
              const Border(left: BorderSide(color: ScribTheme.primary, width: 4)),
          borderRadius: BorderRadius.circular(4),
        ),
        code: const TextStyle(
            fontFamily: 'monospace',
            backgroundColor: ScribTheme.surfaceVariant,
            fontSize: 13),
        tableHead: const TextStyle(
            fontWeight: FontWeight.bold, color: ScribTheme.onSurface),
        tableBody:
            const TextStyle(fontSize: 13, color: ScribTheme.onSurface),
      ),
    );
  }
}

// ─── Tab 2: Summary + Key Points ─────────────────────────────────────────────

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.notes});
  final LectureNotes notes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Topics chips
        if (notes.topics.isNotEmpty) ...[
          Text('Topics Covered',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: notes.topics
                .map((t) => _TopicChip(label: t))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Summary card
        _SectionCard(
          icon: Icons.summarize_outlined,
          title: 'Summary',
          child: Text(
            notes.summary,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.6),
          ),
        ),
        const SizedBox(height: 16),

        // Key points
        _SectionCard(
          icon: Icons.lightbulb_outline,
          title: 'Key Points',
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
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ScribTheme.secondary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ScribTheme.secondary.withOpacity(0.4)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: ScribTheme.secondary,
                fontWeight: FontWeight.w500)),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.icon,
      required this.title,
      required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ScribTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ScribTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
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
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: ScribTheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$index',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ScribTheme.primary)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      );
}

// ─── Tab 3: Flashcards ────────────────────────────────────────────────────────
//
// TODO (Member 4 — Commit 1):
//   Replace this placeholder with a proper swipeable flashcard deck.
//   Each card should flip on tap to reveal the answer.
//   Use the flutter_animate package for the 3D flip effect.
//   Add a progress indicator showing how many cards have been reviewed.

class _FlashcardsView extends StatefulWidget {
  const _FlashcardsView({required this.notes});
  final LectureNotes notes;

  @override
  State<_FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends State<_FlashcardsView> {
  int _current = 0;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final cards = widget.notes.flashcards;
    if (cards.isEmpty) {
      return const Center(child: Text('No flashcards generated.'));
    }

    final card = cards[_current];

    return Column(
      children: [
        const SizedBox(height: 16),
        Text('${_current + 1} / ${cards.length}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),

        // Card
        GestureDetector(
          onTap: () => setState(() => _showAnswer = !_showAnswer),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            height: 260,
            decoration: BoxDecoration(
              color: _showAnswer
                  ? ScribTheme.secondary.withOpacity(0.15)
                  : ScribTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _showAnswer
                    ? ScribTheme.secondary
                    : ScribTheme.surfaceVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showAnswer ? 'Answer' : 'Question',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _showAnswer
                          ? ScribTheme.secondary
                          : ScribTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  _showAnswer ? card.answer : card.question,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 18, height: 1.5),
                ),
                const SizedBox(height: 16),
                Text('Tap to flip',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.arrow_back),
              onPressed: _current > 0
                  ? () => setState(() {
                        _current--;
                        _showAnswer = false;
                      })
                  : null,
            ),
            const SizedBox(width: 24),
            IconButton.outlined(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _current < cards.length - 1
                  ? () => setState(() {
                        _current++;
                        _showAnswer = false;
                      })
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Tab 4: Raw Transcript ────────────────────────────────────────────────────
//
// TODO (Member 4 — Commit 2):
//   Add a search bar at the top that highlights matching words in the text.
//   Use a ScrollController to jump to the first match.

class _TranscriptView extends StatelessWidget {
  const _TranscriptView({required this.transcript});
  final String? transcript;

  @override
  Widget build(BuildContext context) {
    if (transcript == null || transcript!.isEmpty) {
      return const Center(child: Text('Transcript not available.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        transcript!,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(height: 1.7, color: ScribTheme.textSecondary),
      ),
    );
  }
}