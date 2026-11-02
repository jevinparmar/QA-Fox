import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../utils/logger.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _fcm;

  FirebaseMessagingService([FirebaseMessaging? fcm])
    : _fcm = fcm ?? FirebaseMessaging.instance;

  Future<String?> getToken() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // ignore: deprecated_member_use
        return await _fcm.getToken();
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get FCM token', e);
      return null;
    }
  }

  void initializeForegroundHandler({
    required void Function(RemoteMessage message) onMessageReceived,
  }) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info(
        'Foreground message received: ${message.notification?.title}',
      );
      onMessageReceived(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('Notification opened app: ${message.data}');
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb) {
      try {
        await _fcm.subscribeToTopic(topic);
      } catch (e) {
        AppLogger.error('Failed to subscribe to topic: $topic', e);
      }
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb) {
      try {
        await _fcm.unsubscribeFromTopic(topic);
      } catch (e) {
        AppLogger.error('Failed to unsubscribe from topic: $topic', e);
      }
    }
  }
}
