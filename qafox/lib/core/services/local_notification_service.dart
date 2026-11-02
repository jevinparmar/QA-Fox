import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

class LocalNotificationService {
  const LocalNotificationService();

  Future<void> initialize() async {
    AppLogger.info('LocalNotificationService initialized');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kDebugMode) {
      debugPrint('[NOTIFICATION] $title: $body (payload: $payload)');
    }
  }
}
