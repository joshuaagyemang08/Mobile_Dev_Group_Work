import 'package:flutter/material.dart';

import '../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Scrib 1.0.0'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: ScribTheme.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: ScribTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scrib',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'A lecture transcription and note-generation platform built to help students capture lessons, summarize key ideas, and study faster.',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'What Scrib does',
            items: const [
              'Records lectures and captures audio for later review.',
              'Creates transcripts, summaries, notes, and study material.',
              'Keeps your learning content organized in one place.',
              'Supports account sign-in, profile details, and theme preferences.',
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Version details',
            items: const [
              'App label: Scrib 1.0.0',
              'Built with Flutter and Dart',
              'Backend auth and storage powered by Supabase',
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Notes',
            items: const [
              'This app is designed for personal study and lecture organization.',
              'Always review generated transcripts and summaries for accuracy.',
              'If a feature is not opening, return to the profile page and try again after reopening the app.',
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: ScribTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
