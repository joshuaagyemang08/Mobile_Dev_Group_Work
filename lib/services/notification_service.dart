// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'scrib_channel';
  static const _channelName = 'Scrib Notifications';
  static const _channelDesc = 'Notifications for lecture processing status';

  static Future<void> init() async {
    // Request permission on Android 13+
    await Permission.notification.request();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

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

  static Future<void> showNotesReady(String lectureTitle) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      lectureTitle.hashCode.abs() % 2147483647,
      'Notes Ready!',
      'Your notes for "$lectureTitle" are ready to view.',
      details,
    );
  }

  static Future<void> showProcessingFailed(String lectureTitle) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(
      lectureTitle.hashCode.abs() % 2147483647,
      'Processing Failed',
      '"$lectureTitle" could not be processed. Tap to retry.',
      details,
    );
  }
}
