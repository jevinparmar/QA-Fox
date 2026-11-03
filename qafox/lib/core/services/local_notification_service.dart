import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/logger.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'qafox_channel_high';
  static const String channelName = 'QA Fox Notifications';
  static const String channelDescription =
      'Real-time notifications for incoming chat messages, bugs, and connection requests.';

  Future<void> initialize({
    void Function(NotificationResponse response)? onNotificationTapped,
  }) async {
    if (kIsWeb) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: onNotificationTapped,
      );

      // Create High Importance Notification Channel on Android
      final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      AppLogger.info('LocalNotificationService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize LocalNotificationService', e);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('[WEB NOTIFICATION] $title: $body');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      AppLogger.error('Failed to display local notification', e);
    }
  }
}
