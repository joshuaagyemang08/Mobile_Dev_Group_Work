// lib/screens/about_screen.dart

import 'package:flutter/material.dart';
import '../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About Scrib'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // App Logo Placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [ScribTheme.primary, Color(0xFF7B6FF0)],
                ),
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'Scrib',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoSection(
              context,
              title: 'What is Scrib?',
              description:
                  'Scrib is an AI-powered lecture transcription and note-generation platform designed to help students study smarter, not harder.',
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              title: 'How it works',
              description:
                  'Simply record your lectures directly in the app. Our advanced AI transcribes the audio in real-time and automatically generates concise, structured study notes, summaries, and key takeaways for you.',
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              title: 'Our Mission',
              description:
                  'We aim to bridge the gap between listening and learning by removing the stress of manual note-taking, allowing students to focus entirely on the lecture content.',
            ),
            const SizedBox(height: 60),
            Text(
              '© 2024 Scrib AI Inc.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context,
      {required String title, required String description}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ScribTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
