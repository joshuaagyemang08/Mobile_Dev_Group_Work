// lib/screens/home_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../models/lecture.dart';
import '../providers/lecture_provider.dart';
import '../providers/language_provider.dart';
import 'recording_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String? _profileImagePath;
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
    final imagePath = prefs.getString('user_profile_image');
    if (mounted) {
      setState(() {
        _userName = name.split(' ').first; // first name only
        _profileImagePath = imagePath;
      });
    }
  }

  String _getGreeting(LanguageProvider lp) {
    final hour = DateTime.now().hour;
    if (hour < 12) return lp.translate('good_morning');
    if (hour < 17) return lp.translate('good_afternoon');
    return lp.translate('good_evening');
  }

  List<Lecture> _filtered(List<Lecture> lectures) {
    return lectures.where((l) {
      final matchesSearch = _searchQuery.isEmpty ||
          l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (l.subject?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesSubject =
          _selectedSubject == null || l.subject == _selectedSubject;
      return matchesSearch && matchesSubject;
    }).toList();
  }

  List<String> _subjects(List<Lecture> lectures) {
    return lectures
        .map((l) => l.subject)
        .whereType<String>()
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<LectureProvider>(
        builder: (context, provider, _) {
          final lectures = provider.lectures;
          final filtered = _filtered(lectures);
          final subjects = _subjects(lectures);

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName.isNotEmpty
                                      ? '${_getGreeting(lp)}, $_userName! 👋'
                                      : '${_getGreeting(lp)}! 👋',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, MMMM d', lp.locale.languageCode).format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? ScribTheme.textSecondaryDark 
                                        : ScribTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            // Avatar
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ProfileScreen()),
                                );
                                _loadUser(); // Refresh user data when returning
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).cardTheme.color,
                                  border: Border.all(
                                    color: ScribTheme.primary.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _buildAvatarImage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _SearchBar(
                      controller: _searchController,
                      hintText: lp.translate('search_hint'),
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                  ),
                ),
              ),

              // ── Stats ────────────────────────────────────────────────────
              if (lectures.isNotEmpty)
                SliverToBoxAdapter(
                  child: _StatsRow(lectures: lectures, lp: lp),
                ),

              // ── Subject filter chips ──────────────────────────────────────
              if (subjects.isNotEmpty)
                SliverToBoxAdapter(
                  child: _SubjectChips(
                    subjects: subjects,
                    selected: _selectedSubject,
                    onSelect: (s) =>
                        setState(() => _selectedSubject = s),
                  ),
                ),

              // ── Section header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty || _selectedSubject != null
                            ? '${filtered.length} ${filtered.length == 1 ? lp.translate('result') : lp.translate('results')}'
                            : lp.translate('your_lectures'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (_selectedSubject != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedSubject = null),
                          child: Text(
                            lp.translate('clear_filter'),
                            style: const TextStyle(
                                color: ScribTheme.primary, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Lecture list or empty state ───────────────────────────────
              if (lectures.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                      onRecord: () => _startRecording(context), lp: lp),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _NoResultsState(
                    query: _searchQuery,
                    lp: lp,
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedSubject = null;
                        _searchController.clear();
                      });
                    },
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
                                color: Colors.white, size: 26),
                          ),
                          onDismissed: (_) =>
                              context.read<LectureProvider>().deleteLecture(lecture.id),
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
        icon: const Icon(Icons.mic),
        label: Text(lp.translate('record_lecture')),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_profileImagePath == null || _profileImagePath!.isEmpty) {
      return _buildDefaultAvatar();
    }

    if (kIsWeb) {
      return Image.network(
        _profileImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else {
      final file = File(_profileImagePath!);
      if (!file.existsSync()) return _buildDefaultAvatar();
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ScribTheme.primary, Color(0xFF7B6FF0)],
        ),
      ),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged, required this.hintText});
  final TextEditingController controller;
  final String hintText;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight, 
            fontSize: 13
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight, 
              size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.lectures, required this.lp});
  final List<Lecture> lectures;
  final LanguageProvider lp;

  @override
  Widget build(BuildContext context) {
    final completed =
        lectures.where((l) => l.status == LectureStatus.completed).length;
    final totalMinutes =
        lectures.fold(Duration.zero, (acc, l) => acc + l.duration).inMinutes;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final hoursLabel = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatCard(
            label: lp.translate('lectures_stat'),
            value: '${lectures.length}',
            icon: Icons.play_circle_outline_rounded,
            color: ScribTheme.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: lp.translate('notes_ready_stat'),
            value: '$completed',
            icon: Icons.description_outlined,
            color: ScribTheme.secondary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: lp.translate('recorded_stat'),
            value: hoursLabel,
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
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, 
                color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subject Filter Chips ─────────────────────────────────────────────────────
class _SubjectChips extends StatelessWidget {
  const _SubjectChips({
    required this.subjects,
    required this.selected,
    required this.onSelect,
  });
  final List<String> subjects;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? ScribTheme.primary
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? ScribTheme.primary
                      : isDark ? ScribTheme.surfaceVariantDark : ScribTheme.surfaceVariantLight,
                ),
              ),
              child: Text(
                subject,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight,
                ),
              ),
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

  Color get _subjectColor {
    if (lecture.subject == null) return ScribTheme.primary;
    final colors = [
      ScribTheme.primary,
      ScribTheme.secondary,
      const Color(0xFFF5A623),
      const Color(0xFFE95B9B),
      const Color(0xFF5BC8F5),
    ];
    return colors[lecture.subject!.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            : lecture.status == LectureStatus.failed
                ? () => _showFailedDialog(context, lecture)
                : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Color-coded subject icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _statusIcon(lecture.status),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lecture.subject != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lecture.subject!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatDuration(lecture.duration),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${DateFormat('MMM d').format(lecture.recordedAt)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight
                          ),
                        ),
                      ],
                    ),
                    if (lecture.status != LectureStatus.completed &&
                        lecture.status != LectureStatus.failed) ...[
                      const SizedBox(height: 8),
                      _ProcessingIndicator(lecture: lecture),
                    ],
                    if (lecture.status == LectureStatus.failed) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Processing failed — tap to retry',
                        style: TextStyle(
                            fontSize: 12, color: ScribTheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              if (lecture.status == LectureStatus.completed)
                Icon(Icons.chevron_right,
                    color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight)
              else
                GestureDetector(
                  onTap: () => context
                      .read<LectureProvider>().deleteLecture(lecture.id),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: ScribTheme.error, size: 20),
                ),
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
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Processing Failed',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          lecture.errorMessage ?? 'Unknown error',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight, 
            fontSize: 13
          ),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.retryLecture(lecture.id);
            },
            child: const Text('Retry',
                style: TextStyle(color: ScribTheme.primary)),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(LectureStatus status) => switch (status) {
        LectureStatus.completed => Icons.check_circle_outline_rounded,
        LectureStatus.failed => Icons.error_outline_rounded,
        _ => Icons.hourglass_empty_rounded,
      };

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _ProcessingIndicator extends StatelessWidget {
  const _ProcessingIndicator({required this.lecture});
  final Lecture lecture;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        Text(label,
            style: TextStyle(
                fontSize: 12, 
                color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight
            )),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: lecture.status == LectureStatus.uploading
              ? lecture.uploadProgress
              : null,
          backgroundColor: isDark ? ScribTheme.surfaceVariantDark : ScribTheme.surfaceVariantLight,
          color: ScribTheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRecord, required this.lp});
  final VoidCallback onRecord;
  final LanguageProvider lp;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: ScribTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_none_rounded,
                  size: 48, color: ScribTheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              lp.translate('no_lectures'),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              lp.translate('no_lectures_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, 
                color: Theme.of(context).brightness == Brightness.dark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight, 
                height: 1.5
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRecord,
              icon: const Icon(Icons.mic),
              label: Text(lp.translate('start_recording')),
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

// ─── No Results State ─────────────────────────────────────────────────────────
class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query, required this.onClear, required this.lp});
  final String query;
  final LanguageProvider lp;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, 
              color: Theme.of(context).brightness == Brightness.dark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight),
          const SizedBox(height: 16),
          Text(
            lp.translate('no_results'),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            '${lp.translate('nothing_matched')} "$query"',
            style: TextStyle(
                fontSize: 13, 
                color: Theme.of(context).brightness == Brightness.dark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onClear,
            child: Text(lp.translate('clear_search'),
                style: const TextStyle(color: ScribTheme.primary)),
          ),
        ],
      ),
    );
  }
}
