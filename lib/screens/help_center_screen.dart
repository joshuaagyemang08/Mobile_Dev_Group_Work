import 'package:flutter/material.dart';

import '../core/theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeaderCard(
            icon: Icons.support_agent_rounded,
            title: 'How Scrib helps you',
            body:
                'Scrib turns lectures into transcripts, summaries, notes, and study material so you can review faster and stay organized.',
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Common questions',
            items: const [
              _BulletItem(
                title: 'Recording is not starting',
                body:
                    'Check microphone permission in your device settings, then try again from the Recording screen.',
              ),
              _BulletItem(
                title: 'Transcript looks incomplete',
                body:
                    'Speak clearly near the device and keep the audio steady. Long pauses or background noise can reduce accuracy.',
              ),
              _BulletItem(
                title: 'Summary or notes did not appear',
                body:
                    'Make sure the recording finished processing. If it still does not load, go back and reopen the lecture from your saved list.',
              ),
              _BulletItem(
                title: 'Email verification is not working',
                body:
                    'Use the verification link from your inbox, then return to the app and tap I have verified. If the page opens in a browser, come back to Scrib and continue there.',
              ),
              _BulletItem(
                title: 'Google sign-in fails',
                body:
                    'Confirm you are using the correct Google account, and that the app was configured with the right package name and SHA-1 key.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Best results',
            items: const [
              _BulletItem(
                title: 'Use a quiet room',
                body: 'Cleaner audio gives better transcripts and summaries.',
              ),
              _BulletItem(
                title: 'Keep the phone close',
                body: 'Distance matters when capturing voices in a lecture hall.',
              ),
              _BulletItem(
                title: 'Review the summary first',
                body: 'Summaries are a fast way to confirm the lecture was captured correctly.',
              ),
              _BulletItem(
                title: 'Save important lectures',
                body: 'Use your stored notes and profile settings to keep study content organized.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FooterCard(
            color: theme.cardTheme.color ?? Colors.white,
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ScribTheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: ScribTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.items});

  final String title;
  final List<_BulletItem> items;

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
            const SizedBox(height: 14),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: item,
                )),
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: ScribTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterCard extends StatelessWidget {
  const _FooterCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need more help?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text(
              'If something still is not working, log out and sign back in, then try the feature again. For account or verification issues, start from the login screen.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 14),
            Text(
              'Email: joshuaagyemang08@gmail.com',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
