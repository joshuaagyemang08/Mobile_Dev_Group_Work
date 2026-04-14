// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

// ── Slide data ────────────────────────────────────────────────────────────────
class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<String> tags;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.tags,
  });
}

const _slides = [
  _Slide(
    icon: Icons.mic_rounded,
    title: 'Record Your\nLectures',
    subtitle:
        'Capture every word with crystal-clear audio. Just tap record and focus on learning.',
    gradient: [Color(0xFF5B4FE9), Color(0xFF3A2FC4)],
    tags: ['Up to 3 hours', 'Background recording', 'HD Audio'],
  ),
  _Slide(
    icon: Icons.record_voice_over_rounded,
    title: 'Instant\nTranscription',
    subtitle:
        'AI converts your recordings to searchable text in minutes — with speaker detection.',
    gradient: [Color(0xFF00C9A7), Color(0xFF007D6A)],
    tags: ['Speaker detection', '99% accurate', 'Searchable text'],
  ),
  _Slide(
    icon: Icons.auto_awesome_rounded,
    title: 'Study\nSmarter',
    subtitle:
        'Get summaries, flashcards, and key takeaways generated automatically for every lecture.',
    gradient: [Color(0xFFF5A623), Color(0xFFD4870A)],
    tags: ['AI summaries', 'Flashcards', 'Key topics'],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _current = 0;

  // Animated background colour tween
  late AnimationController _bgController;
  late Animation<Color?> _bgTop;
  late Animation<Color?> _bgBottom;

  final _topColors = [
    for (final s in _slides) s.gradient[0],
  ];
  final _bottomColors = [
    for (final s in _slides) s.gradient[1],
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bgTop = ColorTween(
            begin: _topColors[0], end: _topColors[0])
        .animate(_bgController);
    _bgBottom = ColorTween(
            begin: _bottomColors[0], end: _bottomColors[0])
        .animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _bgTop = ColorTween(
      begin: _topColors[_current],
      end: _topColors[index],
    ).animate(
        CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _bgBottom = ColorTween(
      begin: _bottomColors[_current],
      end: _bottomColors[index],
    ).animate(
        CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _bgController
      ..reset()
      ..forward();
    setState(() => _current = index);
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => const AuthScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLast = _current == _slides.length - 1;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _bgTop.value ?? _slides[_current].gradient[0],
                _bgBottom.value ?? _slides[_current].gradient[1],
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.auto_stories_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Scrib',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      // Skip
                      AnimatedOpacity(
                        opacity: isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTap: isLast ? null : _finish,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Illustration area ─────────────────────────────
                SizedBox(
                  height: size.height * 0.38,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) =>
                        _IllustrationView(slide: _slides[i], active: i == _current),
                  ),
                ),

                // ── Bottom card ───────────────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36)),
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 36, 32, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _slides[_current].title,
                            key: ValueKey(_current),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Subtitle
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _slides[_current].subtitle,
                            key: ValueKey('sub$_current'),
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Feature tags
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Wrap(
                            key: ValueKey('tags$_current'),
                            spacing: 8,
                            runSpacing: 8,
                            children: _slides[_current]
                                .tags
                                .map((t) => _Tag(
                                    label: t,
                                    color: _slides[_current].gradient[0]))
                                .toList(),
                          ),
                        ),

                        const Spacer(),

                        // Dot indicators
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                _slides.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: _current == i ? 28 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _current == i
                                        ? _slides[_current].gradient[0]
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Next / Get Started button
                            GestureDetector(
                              onTap: _next,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLast ? 28 : 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _slides[_current].gradient,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _slides[_current]
                                          .gradient[0]
                                          .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLast)
                                      const Text(
                                        'Get Started',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 22),
                                    if (isLast) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.rocket_launch_rounded,
                                          color: Colors.white, size: 18),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Illustration view ─────────────────────────────────────────────────────────
class _IllustrationView extends StatelessWidget {
  const _IllustrationView({required this.slide, required this.active});
  final _Slide slide;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: active
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Layered glow rings + icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    // Mid ring
                    Container(
                      width: 155,
                      height: 155,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    // Icon container
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(slide.icon, color: Colors.white, size: 52),
                    ),
                  ],
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.6, 0.6),
                        duration: 600.ms,
                        curve: Curves.elasticOut)
                    .fadeIn(duration: 400.ms),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

// ── Feature tag pill ──────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
  }
}
