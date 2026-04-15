// lib/services/notification_service.dart

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'scrib_channel';
  static const _channelName = 'Scrib Notifications';
  static const _channelDesc = 'Notifications for lecture processing status';
  static const _lectureReadyPrefKey = 'notify_lecture_ready';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: iOS);
    await _plugin.initialize(settings);
    _initialized = true;

    // Ask notification permission during startup so it is ready for lecture completion.
    await requestPermission();

    // Create the Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }

      if (Platform.isIOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isLectureReadyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lectureReadyPrefKey) ?? true;
  }

  static Future<bool> _canNotify() async {
    if (!_initialized) return false;

    final permission = await requestPermission();
    if (!permission) return false;

    return true;
  }

  static Future<void> showNotesReady(String lectureTitle) async {
    try {
      if (!await _isLectureReadyEnabled()) return;
      if (!await _canNotify()) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.show(
        lectureTitle.hashCode.abs() % 2147483647,
        'Notes Ready!',
        'Your notes for "$lectureTitle" are ready to view.',
        details,
      );
    } catch (_) {
      // Never fail lecture processing because a notification failed.
    }
  }

  static Future<void> showProcessingFailed(String lectureTitle) async {
    try {
      if (!await _canNotify()) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.show(
        lectureTitle.hashCode.abs() % 2147483647,
        'Processing Failed',
        '"$lectureTitle" could not be processed. Tap to retry.',
        details,
      );
    } catch (_) {
      // Ignore notification errors to keep app flow stable.
    }
  }
}
