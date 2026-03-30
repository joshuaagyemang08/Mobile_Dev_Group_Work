// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.mic_rounded,
      iconColor: ScribTheme.primary,
      title: 'Record Your Lectures',
      subtitle:
          'Never miss a word. Capture every lecture with crystal-clear audio recording — up to 3 hours long.',
      gradient: [Color(0xFF5B4FE9), Color(0xFF3D35B0)],
    ),
    _SlideData(
      icon: Icons.text_snippet_rounded,
      iconColor: ScribTheme.secondary,
      title: 'Instant Transcription',
      subtitle:
          'AI automatically converts your recordings into searchable text, and even identifies who is speaking.',
      gradient: [Color(0xFF00C9A7), Color(0xFF009E85)],
    ),
    _SlideData(
      icon: Icons.auto_awesome_rounded,
      iconColor: Color(0xFFF5A623),
      title: 'Study Smarter',
      subtitle:
          'Get AI-generated summaries, flashcards, and key takeaways — everything you need to ace your exams.',
      gradient: [Color(0xFFF5A623), Color(0xFFE08A0E)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const AuthScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: ScribTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: AnimatedOpacity(
                  opacity: isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: isLast ? null : _finishOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: ScribTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i
                        ? ScribTheme.primary
                        : ScribTheme.surfaceVariant,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: isLast
                          ? [ScribTheme.secondary, const Color(0xFF009E85)]
                          : [ScribTheme.primary, const Color(0xFF7B6FF0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLast ? ScribTheme.secondary : ScribTheme.primary)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _nextPage,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Slide Data Model ──────────────────────────────────────────────────────────
class _SlideData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _SlideData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

// ── Slide View ────────────────────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  slide.iconColor.withOpacity(0.2),
                  slide.iconColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: slide.gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: slide.iconColor.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(slide.icon, color: Colors.white, size: 50),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ScribTheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: ScribTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
