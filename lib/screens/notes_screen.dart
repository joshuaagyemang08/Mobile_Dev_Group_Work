// lib/screens/notes_screen.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/theme.dart';
import '../models/lecture.dart';
import '../providers/lecture_provider.dart';

class NotesScreen extends StatefulWidget {
  final Lecture lecture;
  const NotesScreen({super.key, required this.lecture});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 5, vsync: this);

  // ── Audio player state ────────────────────────────────────────────────────
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(widget.lecture.audioPath));
    }
  }

  Future<void> _seekTo(double value) async {
    final pos = Duration(milliseconds: (value * _total.inMilliseconds).round());
    await _player.seek(pos);
  }

  // ── Camera ────────────────────────────────────────────────────────────────
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      context.read<LectureProvider>().addPhoto(widget.lecture.id, picked.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      context.read<LectureProvider>().addPhoto(widget.lecture.id, picked.path);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LectureProvider>(
      builder: (context, provider, _) {
        // Always get the latest lecture from provider so photos update live
        final lecture = provider.lectures.firstWhere(
          (l) => l.id == widget.lecture.id,
          orElse: () => widget.lecture,
        );
        final notes = lecture.notes;

        return Scaffold(
          backgroundColor: ScribTheme.background,
          appBar: AppBar(
            backgroundColor: ScribTheme.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: ScribTheme.onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ScribTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lecture.subject != null)
                  Text(
                    lecture.subject!,
                    style: const TextStyle(
                        fontSize: 12, color: ScribTheme.textSecondary),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_outlined,
                    color: ScribTheme.textSecondary, size: 20),
                tooltip: 'Copy notes',
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: notes?.fullNotes ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Notes copied to clipboard'),
                        ],
                      ),
                      backgroundColor: ScribTheme.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: ScribTheme.surfaceVariant, width: 1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: ScribTheme.primary,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: ScribTheme.primary,
                  unselectedLabelColor: ScribTheme.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    const Tab(text: 'Notes'),
                    const Tab(text: 'Summary'),
                    const Tab(text: 'Flashcards'),
                    const Tab(text: 'Transcript'),
                    Tab(
                      child: Row(
                        children: [
                          const Text('Photos'),
                          if (lecture.photoPaths.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: ScribTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${lecture.photoPaths.length}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Audio player bar at the bottom
          bottomNavigationBar: _AudioPlayerBar(
            audioPath: lecture.audioPath,
            playerState: _playerState,
            position: _position,
            total: _total,
            onToggle: _togglePlayback,
            onSeek: _seekTo,
            formatDuration: _formatDuration,
          ),
          body: notes == null
              ? _buildNoNotes()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _NotesTab(notes: notes),
                    _SummaryTab(notes: notes),
                    _FlashcardsTab(flashcards: notes.flashcards),
                    _TranscriptTab(transcript: lecture.transcript),
                    _PhotosTab(
                      lecture: lecture,
                      onTakePhoto: _takePhoto,
                      onPickGallery: _pickFromGallery,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildNoNotes() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              color: ScribTheme.textSecondary, size: 52),
          SizedBox(height: 16),
          Text('Notes not available',
              style: TextStyle(
                  fontSize: 16, color: ScribTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Audio Player Bar ─────────────────────────────────────────────────────────

class _AudioPlayerBar extends StatelessWidget {
  const _AudioPlayerBar({
    required this.audioPath,
    required this.playerState,
    required this.position,
    required this.total,
    required this.onToggle,
    required this.onSeek,
    required this.formatDuration,
  });

  final String audioPath;
  final PlayerState playerState;
  final Duration position;
  final Duration total;
  final VoidCallback onToggle;
  final void Function(double) onSeek;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final isPlaying = playerState == PlayerState.playing;
    final progress = total.inMilliseconds > 0
        ? position.inMilliseconds / total.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: ScribTheme.surface,
        border: const Border(
            top: BorderSide(color: ScribTheme.surfaceVariant, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ScribTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: ScribTheme.primary, size: 14),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Lecture Recording',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ScribTheme.onSurface),
                  ),
                ),
                Text(
                  '${formatDuration(position)} / ${formatDuration(total)}',
                  style: const TextStyle(
                      fontSize: 11, color: ScribTheme.textSecondary),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ScribTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: ScribTheme.primary,
                inactiveTrackColor: ScribTheme.surfaceVariant,
                thumbColor: ScribTheme.primary,
                overlayColor: ScribTheme.primary.withOpacity(0.2),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: onSeek,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Notes ─────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes});
  final LectureNotes notes;

  @override
  Widget build(BuildContext context) {
    final fullNotes = notes.fullNotes;

    if (fullNotes.isEmpty) {
      return const Center(
        child: Text('No notes content',
            style: TextStyle(color: ScribTheme.textSecondary)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: ScribTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ScribTheme.surfaceVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ScribTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      size: 18, color: ScribTheme.primary),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Lecture Notes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ScribTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ScribTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ScribTheme.surfaceVariant),
            ),
            child: _MarkdownText(content: fullNotes),
          ),
        ],
      ),
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      final numbered = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);

      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Text(_cleanInlineMarkdown(line.substring(2)),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ScribTheme.onSurface)),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: ScribTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(_cleanInlineMarkdown(line.substring(3)),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ScribTheme.primary)),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(_cleanInlineMarkdown(line.substring(4)),
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: ScribTheme.secondary)),
        ));
      } else if (numbered != null) {
        final number = numbered.group(1) ?? '';
        final body = _cleanInlineMarkdown(numbered.group(2) ?? '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: BoxDecoration(
                  color: ScribTheme.primary.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ScribTheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ScribTheme.onSurface,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 7, right: 8),
                child: Icon(Icons.circle,
                    size: 5, color: ScribTheme.textSecondary),
              ),
              Expanded(
                child: Text(
                  _cleanInlineMarkdown(line.substring(2)),
                  style: const TextStyle(
                      fontSize: 14,
                      color: ScribTheme.onSurface,
                      height: 1.6),
                ),
              ),
            ],
          ),
        ));
      } else if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(_cleanInlineMarkdown(line),
              style: const TextStyle(
                  fontSize: 14.5,
                  color: ScribTheme.onSurface,
                  height: 1.6)),
        ));
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

String _cleanInlineMarkdown(String input) {
  return input
      .replaceAll('**', '')
      .replaceAll('__', '')
      .replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m.group(1) ?? '');
}

// ─── Tab 2: Summary ───────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.notes});
  final LectureNotes notes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notes.summary.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ScribTheme.primary.withOpacity(0.22),
                    ScribTheme.secondary.withOpacity(0.16),
                  ],
                ),
                border: Border.all(
                  color: ScribTheme.primary.withOpacity(0.24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ScribTheme.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.summarize_rounded,
                            color: ScribTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Quick Summary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ScribTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cleanInlineMarkdown(notes.summary),
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: ScribTheme.onSurface,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Topics
          if (notes.topics.isNotEmpty) ...[
            const Text('Topics Covered',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ScribTheme.textSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notes.topics
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: ScribTheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: ScribTheme.secondary.withOpacity(0.3)),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 12,
                                color: ScribTheme.secondary,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Key Points
          if (notes.keyPoints.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ScribTheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded,
                      color: ScribTheme.secondary, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('Key Points',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ScribTheme.onSurface)),
              ],
            ),
            const SizedBox(height: 12),
            ...notes.keyPoints.asMap().entries.map(
                  (e) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: ScribTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ScribTheme.surfaceVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 10, top: 1),
                          decoration: BoxDecoration(
                            color: ScribTheme.primary.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ScribTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _cleanInlineMarkdown(e.value),
                            style: const TextStyle(
                              fontSize: 14,
                              color: ScribTheme.onSurface,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Tab 3: Flashcards ────────────────────────────────────────────────────────

class _FlashcardsTab extends StatefulWidget {
  const _FlashcardsTab({required this.flashcards});
  final List<Flashcard> flashcards;

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _flipAnim =
      Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
  );

  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _goToCard(int index) {
    if (index < 0 || index >= widget.flashcards.length) return;
    _flipController.value = 0;
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined,
                color: ScribTheme.textSecondary, size: 48),
            SizedBox(height: 16),
            Text('No flashcards available',
                style: TextStyle(color: ScribTheme.textSecondary)),
          ],
        ),
      );
    }

    final card = widget.flashcards[_currentIndex];
    final total = widget.flashcards.length;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Text('${_currentIndex + 1} / $total',
                  style: const TextStyle(
                      fontSize: 13, color: ScribTheme.textSecondary)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / total,
                    backgroundColor: ScribTheme.surfaceVariant,
                    color: ScribTheme.primary,
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3D Flip card
        Expanded(
          child: GestureDetector(
            onTap: _flip,
            onHorizontalDragEnd: (d) {
              if (d.primaryVelocity == null) return;
              if (d.primaryVelocity! < -300) {
                _goToCard(_currentIndex + 1);
              } else if (d.primaryVelocity! > 300) {
                _goToCard(_currentIndex - 1);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, __) {
                  final angle = _flipAnim.value * math.pi;
                  final isShowingFront = angle < math.pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isShowingFront
                        ? _CardFace(
                            label: 'Q',
                            labelColor: ScribTheme.primary,
                            text: card.question,
                            hint: 'Tap to reveal answer',
                            bgColor: ScribTheme.surface,
                            borderColor: ScribTheme.primary.withOpacity(0.3),
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _CardFace(
                              label: 'A',
                              labelColor: ScribTheme.secondary,
                              text: card.answer,
                              hint: 'Tap to see question',
                              bgColor: ScribTheme.secondary.withOpacity(0.06),
                              borderColor:
                                  ScribTheme.secondary.withOpacity(0.3),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            total,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentIndex ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _currentIndex
                    ? ScribTheme.primary
                    : ScribTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () => _goToCard(_currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScribTheme.textSecondary,
                    side: const BorderSide(color: ScribTheme.surfaceVariant),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _currentIndex < total - 1
                      ? () => _goToCard(_currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14),
                  label: const Text('Next'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ScribTheme.primary,
                    disabledBackgroundColor: ScribTheme.surfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.label,
    required this.labelColor,
    required this.text,
    required this.hint,
    required this.bgColor,
    required this.borderColor,
  });

  final String label;
  final Color labelColor;
  final String text;
  final String hint;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: labelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: labelColor.withOpacity(0.3)),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                      letterSpacing: 1)),
            ),
            const Spacer(),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: ScribTheme.onSurface,
                height: 1.5,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_outlined,
                    size: 13, color: ScribTheme.textSecondary),
                const SizedBox(width: 4),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 12, color: ScribTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 4: Transcript ────────────────────────────────────────────────────────

class _TranscriptTab extends StatefulWidget {
  const _TranscriptTab({required this.transcript});
  final String? transcript;

  @override
  State<_TranscriptTab> createState() => _TranscriptTabState();
}

class _TranscriptTabState extends State<_TranscriptTab> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.transcript;

    if (text == null || text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_snippet_outlined,
                color: ScribTheme.textSecondary, size: 48),
            SizedBox(height: 16),
            Text('Transcript not available',
                style: TextStyle(
                    fontSize: 15, color: ScribTheme.textSecondary)),
            SizedBox(height: 8),
            Text('Process a recording to see the transcript.',
                style:
                    TextStyle(fontSize: 13, color: ScribTheme.textSecondary)),
          ],
        ),
      );
    }

    final wordCount = text.split(RegExp(r'\s+')).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(
                bottom:
                    BorderSide(color: ScribTheme.surfaceVariant, width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.text_fields_rounded,
                  color: ScribTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text('$wordCount words',
                  style: const TextStyle(
                      fontSize: 13, color: ScribTheme.textSecondary)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  setState(() => _copied = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _copied = false);
                },
                icon: Icon(
                  _copied ? Icons.check_rounded : Icons.copy_outlined,
                  size: 15,
                  color: _copied ? ScribTheme.secondary : ScribTheme.primary,
                ),
                label: Text(
                  _copied ? 'Copied!' : 'Copy',
                  style: TextStyle(
                      fontSize: 13,
                      color: _copied
                          ? ScribTheme.secondary
                          : ScribTheme.primary),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: ScribTheme.onSurface,
                  height: 1.7,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab 5: Photos ────────────────────────────────────────────────────────────

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({
    required this.lecture,
    required this.onTakePhoto,
    required this.onPickGallery,
  });

  final Lecture lecture;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    final photos = lecture.photoPaths;

    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('Take Photo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ScribTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScribTheme.primary,
                    side: BorderSide(
                        color: ScribTheme.primary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (photos.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: ScribTheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        size: 38, color: ScribTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No photos yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ScribTheme.onSurface)),
                  const SizedBox(height: 6),
                  const Text('Capture whiteboard or slides\nfrom this lecture',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: ScribTheme.textSecondary,
                          height: 1.5)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) {
                return _PhotoTile(
                  path: photos[i],
                  onDelete: () => context
                      .read<LectureProvider>()
                      .deletePhoto(lecture.id, photos[i]),
                  onTap: () => _viewPhoto(context, photos, i),
                );
              },
            ),
          ),
      ],
    );
  }

  void _viewPhoto(BuildContext context, List<String> photos, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewScreen(photos: photos, initialIndex: index),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile(
      {required this.path, required this.onDelete, required this.onTap});
  final String path;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: ScribTheme.surface,
                child: const Icon(Icons.broken_image_outlined,
                    color: ScribTheme.textSecondary),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewScreen extends StatefulWidget {
  const _PhotoViewScreen(
      {required this.photos, required this.initialIndex});
  final List<String> photos;
  final int initialIndex;

  @override
  State<_PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<_PhotoViewScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.photos.length}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.file(File(widget.photos[i])),
          ),
        ),
      ),
    );
  }
}
