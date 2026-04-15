import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _PolicySection(
            title: 'What Scrib collects',
            body:
                'Scrib may store your name, email address, profile image, saved preferences, lecture recordings, transcripts, summaries, notes, and feedback you create inside the app.',
          ),
          _PolicySection(
            title: 'How the app uses your data',
            body:
                'Your data is used to sign you in, save your profile, generate and organize your lectures, and keep your study history available across sessions.',
          ),
          _PolicySection(
            title: 'Third-party services',
            body:
                'Scrib uses Supabase for authentication and backend storage, and may use Google sign-in when you choose that login option. Those services handle account verification and sign-in flows.',
          ),
          _PolicySection(
            title: 'Device storage',
            body:
                'The app can save local preferences, cached profile details, and selected images on your device so your experience stays fast and personalized.',
          ),
          _PolicySection(
            title: 'Audio and transcripts',
            body:
                'When you record a lecture, the recording is used to create transcripts, summaries, and notes. Keep only the recordings you want to retain.',
          ),
          _PolicySection(
            title: 'Your choices',
            body:
                'You can edit your profile, log out, remove local data by clearing app storage, and decide what content to keep on your device.',
          ),
          _PolicySection(
            title: 'Security',
            body:
                'Scrib follows normal app security practices, but no system is perfect. Avoid sharing your login credentials and sign out from shared devices.',
          ),
          _PolicySection(
            title: 'Questions',
            body:
                'If you need help with privacy or account access, use the Help Center from your profile screen and review your account settings.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
