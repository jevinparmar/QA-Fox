import '../utils/logger.dart';

class AnalyticsService {
  const AnalyticsService();

  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    AppLogger.info('Analytics Event: $name params: $parameters');
  }

  Future<void> setUserId(String? userId) async {
    AppLogger.info('Analytics setUserId: $userId');
  }
}
