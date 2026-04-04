// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../models/lecture.dart';
import '../providers/lecture_provider.dart';
import 'recording_screen.dart';
import 'notes_screen.dart';
import 'processing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _searchQuery = '';
  String? _selectedSubject;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LectureProvider>().loadLectures();
    });
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    if (mounted) setState(() => _userName = name.split(' ').first);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Lecture> _filtered(List<Lecture> lectures) {
    return lectures.where((l) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          l.title.toLowerCase().contains(q) ||
          (l.subject?.toLowerCase().contains(q) ?? false);
      final matchesSubject =
          _selectedSubject == null || l.subject == _selectedSubject;
      return matchesSearch && matchesSubject;
    }).toList();
  }

  List<String> _subjects(List<Lecture> lectures) =>
      lectures.map((l) => l.subject).whereType<String>().toSet().toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScribTheme.background,
      body: Consumer<LectureProvider>(
        builder: (context, provider, _) {
          final lectures = provider.lectures;
          final filtered = _filtered(lectures);
          final subjects = _subjects(lectures);

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  userName: _userName,
                  greeting: _greeting,
                ),
              ),

              // ── Search ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
              ),

              // ── Stats ─────────────────────────────────────────────────────
              if (lectures.isNotEmpty)
                SliverToBoxAdapter(
                  child: _StatsRow(lectures: lectures),
                ),

              // ── Subject chips ─────────────────────────────────────────────
              if (subjects.isNotEmpty)
                SliverToBoxAdapter(
                  child: _SubjectChips(
                    subjects: subjects,
                    selected: _selectedSubject,
                    onSelect: (s) => setState(() => _selectedSubject = s),
                  ),
                ),

              // ── Section title ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty || _selectedSubject != null
                            ? '${filtered.length} result${filtered.length == 1 ? '' : 's'}'
                            : 'Your Lectures',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ScribTheme.onSurface,
                        ),
                      ),
                      if (_selectedSubject != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSubject = null),
                          child: const Text('Clear',
                              style: TextStyle(
                                  fontSize: 13, color: ScribTheme.primary)),
                        ),
                    ],
                  ),
                ),
              ),

              // ── List ──────────────────────────────────────────────────────
              if (lectures.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                      onRecord: () => _startRecording(context)),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _NoResultsState(
                    query: _searchQuery,
                    onClear: () => setState(() {
                      _searchQuery = '';
                      _selectedSubject = null;
                      _searchController.clear();
                    }),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final lecture = filtered[i];
                        return Dismissible(
                          key: ValueKey(lecture.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: ScribTheme.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 24),
                          ),
                          onDismissed: (_) => context
                              .read<LectureProvider>()
                              .deleteLecture(lecture.id),
                          child: _LectureCard(lecture: lecture),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startRecording(context),
        backgroundColor: ScribTheme.primary,
        icon: const Icon(Icons.mic_rounded, color: Colors.white),
        label: const Text('Record Lecture',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }

  void _startRecording(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const RecordingScreen()));
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.userName, required this.greeting});
  final String userName;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ScribTheme.primary.withOpacity(0.12),
            ScribTheme.background,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ScribTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName.isNotEmpty ? '$userName 👋' : 'Welcome back 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ScribTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: const TextStyle(
                      fontSize: 13, color: ScribTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ScribTheme.primary, Color(0xFF7B6FF0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: ScribTheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: ScribTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ScribTheme.surfaceVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: ScribTheme.onSurface, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search lectures or subjects...',
          hintStyle:
              TextStyle(color: ScribTheme.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: ScribTheme.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.lectures});
  final List<Lecture> lectures;

  @override
  Widget build(BuildContext context) {
    final completed =
        lectures.where((l) => l.status == LectureStatus.completed).length;
    final processing = lectures
        .where((l) =>
            l.status == LectureStatus.uploading ||
            l.status == LectureStatus.transcribing ||
            l.status == LectureStatus.generatingNotes)
        .length;
    final totalMins =
        lectures.fold(Duration.zero, (a, l) => a + l.duration).inMinutes;
    final timeLabel = totalMins >= 60
        ? '${totalMins ~/ 60}h ${totalMins % 60}m'
        : '${totalMins}m';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Total',
            value: '${lectures.length}',
            sublabel: 'lectures',
            icon: Icons.library_books_outlined,
            color: ScribTheme.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Ready',
            value: '$completed',
            sublabel: 'notes',
            icon: Icons.check_circle_outline_rounded,
            color: ScribTheme.secondary,
          ),
          const SizedBox(width: 10),
          if (processing > 0)
            _StatCard(
              label: 'Processing',
              value: '$processing',
              sublabel: 'active',
              icon: Icons.sync_rounded,
              color: const Color(0xFFF5A623),
            )
          else
            _StatCard(
              label: 'Recorded',
              value: timeLabel,
              sublabel: 'total',
              icon: Icons.timer_outlined,
              color: const Color(0xFFF5A623),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.color,
  });
  final String label, value, sublabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: ScribTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: 11, color: ScribTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Subject Filter Chips ─────────────────────────────────────────────────────

class _SubjectChips extends StatelessWidget {
  const _SubjectChips(
      {required this.subjects,
      required this.selected,
      required this.onSelect});
  final List<String> subjects;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final subject = subjects[i];
          final isSelected = selected == subject;
          return GestureDetector(
            onTap: () => onSelect(isSelected ? null : subject),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? ScribTheme.primary
                    : ScribTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? ScribTheme.primary
                      : ScribTheme.surfaceVariant,
                ),
              ),
              child: Text(subject,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : ScribTheme.textSecondary)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Lecture Card ─────────────────────────────────────────────────────────────

class _LectureCard extends StatelessWidget {
  const _LectureCard({required this.lecture});
  final Lecture lecture;

  Color get _color {
    final colors = [
      ScribTheme.primary,
      ScribTheme.secondary,
      const Color(0xFFF5A623),
      const Color(0xFFE95B9B),
      const Color(0xFF5BC8F5),
    ];
    if (lecture.subject != null) {
      return colors[lecture.subject!.hashCode % colors.length];
    }
    return colors[lecture.title.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final isCompleted = lecture.status == LectureStatus.completed;
    final isFailed = lecture.status == LectureStatus.failed;
    final isProcessing = !isCompleted && !isFailed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ScribTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFailed
              ? ScribTheme.error.withOpacity(0.3)
              : isCompleted
                  ? color.withOpacity(0.15)
                  : ScribTheme.surfaceVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isCompleted
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NotesScreen(lecture: lecture)),
                )
            : isFailed
                ? () => _showFailedDialog(context, lecture)
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProcessingScreen(lectureId: lecture.id)),
                    ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(lecture.status),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecture.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ScribTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (lecture.subject != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(lecture.subject!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _formatDuration(lecture.duration),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: ScribTheme.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            const Text('·',
                                style: TextStyle(
                                    color: ScribTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d')
                                  .format(lecture.recordedAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: ScribTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right action
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: color, size: 14),
                    )
                  else if (isFailed)
                    GestureDetector(
                      onTap: () => context
                          .read<LectureProvider>()
                          .deleteLecture(lecture.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ScribTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: ScribTheme.error, size: 16),
                      ),
                    ),
                ],
              ),

              // Processing indicator
              if (isProcessing) ...[
                const SizedBox(height: 14),
                _ProcessingBar(lecture: lecture),
              ],

              // Failed hint
              if (isFailed) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ScribTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline_rounded,
                          color: ScribTheme.error, size: 13),
                      SizedBox(width: 6),
                      Text('Failed — tap to see details',
                          style: TextStyle(
                              fontSize: 12, color: ScribTheme.error)),
                    ],
                  ),
                ),
              ],

              // Notes preview chips
              if (isCompleted && lecture.notes != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PreviewChip(
                      icon: Icons.style_outlined,
                      label:
                          '${lecture.notes!.flashcards.length} flashcards',
                      color: ScribTheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    _PreviewChip(
                      icon: Icons.sell_outlined,
                      label: '${lecture.notes!.topics.length} topics',
                      color: ScribTheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFailedDialog(BuildContext context, Lecture lecture) {
    final provider = context.read<LectureProvider>();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ScribTheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Processing Failed',
            style: TextStyle(color: ScribTheme.onSurface)),
        content: Text(
          lecture.errorMessage ?? 'Unknown error',
          style: const TextStyle(
              color: ScribTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteLecture(lecture.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: ScribTheme.error)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              provider.retryLecture(lecture.id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: ScribTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(LectureStatus s) => switch (s) {
        LectureStatus.completed => Icons.check_circle_outline_rounded,
        LectureStatus.failed => Icons.error_outline_rounded,
        LectureStatus.transcribing => Icons.record_voice_over_outlined,
        LectureStatus.generatingNotes => Icons.auto_awesome_outlined,
        _ => Icons.cloud_upload_outlined,
      };

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProcessingBar extends StatelessWidget {
  const _ProcessingBar({required this.lecture});
  final Lecture lecture;

  @override
  Widget build(BuildContext context) {
    final label = switch (lecture.status) {
      LectureStatus.uploading =>
        'Uploading ${(lecture.uploadProgress * 100).toStringAsFixed(0)}%',
      LectureStatus.transcribing => 'Transcribing speech...',
      LectureStatus.generatingNotes => 'Generating notes...',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: ScribTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: ScribTheme.textSecondary)),
            const Spacer(),
            const Text('Tap to view',
                style: TextStyle(
                    fontSize: 11, color: ScribTheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: lecture.status == LectureStatus.uploading
                ? lecture.uploadProgress
                : null,
            backgroundColor: ScribTheme.surfaceVariant,
            color: ScribTheme.primary,
            minHeight: 3,
          ),
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  ScribTheme.primary.withOpacity(0.15),
                  Colors.transparent,
                ]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_none_rounded,
                  size: 50, color: ScribTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('No lectures yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ScribTheme.onSurface)),
            const SizedBox(height: 8),
            const Text(
              'Record a lecture and let Scrib turn it into structured study notes automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: ScribTheme.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRecord,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Start Recording'),
              style: FilledButton.styleFrom(
                backgroundColor: ScribTheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No Results ───────────────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 52, color: ScribTheme.textSecondary),
          const SizedBox(height: 16),
          const Text('Nothing found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ScribTheme.onSurface)),
          const SizedBox(height: 6),
          Text('No lectures match "$query"',
              style: const TextStyle(
                  fontSize: 13, color: ScribTheme.textSecondary)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear search',
                style: TextStyle(color: ScribTheme.primary)),
          ),
        ],
      ),
    );
  }
}
