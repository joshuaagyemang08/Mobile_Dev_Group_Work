// lib/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _lectureReady = true;
  bool _dailyReminder = false;
  bool _appUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lectureReady = prefs.getBool('notify_lecture_ready') ?? true;
      _dailyReminder = prefs.getBool('notify_daily_reminder') ?? false;
      _appUpdates = prefs.getBool('notify_app_updates') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSwitchTile(
            title: 'Lecture Ready',
            subtitle: 'Get notified when your AI notes are generated',
            value: _lectureReady,
            onChanged: (val) async {
              if (val) {
                final granted = await NotificationService.requestPermission();
                if (!granted) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Notification permission is off. Enable it in phone settings.'),
                    ),
                  );
                  setState(() => _lectureReady = false);
                  await _saveSetting('notify_lecture_ready', false);
                  return;
                }
              }

              setState(() => _lectureReady = val);
              await _saveSetting('notify_lecture_ready', val);
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: 'Daily Study Reminder',
            subtitle: 'A gentle nudge to review your notes',
            value: _dailyReminder,
            onChanged: (val) {
              setState(() => _dailyReminder = val);
              _saveSetting('notify_daily_reminder', val);
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: 'App Updates',
            subtitle: 'New features and improvement alerts',
            value: _appUpdates,
            onChanged: (val) {
              setState(() => _appUpdates = val);
              _saveSetting('notify_app_updates', val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: ScribTheme.primary,
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
}
