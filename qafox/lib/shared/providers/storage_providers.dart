import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/session/session_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/secure_storage_service.dart';

/// Provider for raw [SharedPreferences] initialized in main().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() via ProviderScope',
  );
});

/// Provider for [LocalStorageService] wrapping shared preferences.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.watch(sharedPreferencesProvider));
});

/// Provider for [SecureStorageService].
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.watch(localStorageServiceProvider));
});

/// Provider for [SessionService] managing user sessions.
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.watch(localStorageServiceProvider));
});

