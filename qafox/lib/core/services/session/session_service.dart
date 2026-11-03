import '../../storage/local_storage_service.dart';
import '../../storage/storage_keys.dart';

/// Handles client-side session persistence, cached credentials, and login state.
class SessionService {
  final LocalStorageService _storage;

  SessionService(this._storage);

  /// Whether the user has an active, authenticated session.
  bool get isLoggedIn => _storage.getBool(StorageKeys.isLoggedIn) ?? false;

  /// The cached ID of the currently logged-in user.
  String? get currentUserId => _storage.getString(StorageKeys.currentUserId);

  /// Saved user email (for Remember Me functionality).
  String? get savedEmail => _storage.getString(StorageKeys.sessionEmail);

  /// Whether the user selected "Remember Me".
  bool get isRememberMe => _storage.getBool(StorageKeys.rememberMe) ?? true;

  /// Epoch milliseconds of the last active user session timestamp.
  int? get lastActiveTimestamp => _storage.getInt(StorageKeys.sessionLastActive);

  /// Saves session data on successful authentication.
  Future<void> saveSession({
    required String userId,
    required String email,
    bool rememberMe = true,
  }) async {
    await _storage.setBool(StorageKeys.isLoggedIn, true);
    await _storage.setString(StorageKeys.currentUserId, userId);
    await _storage.setBool(StorageKeys.rememberMe, rememberMe);
    await _storage.setInt(
      StorageKeys.sessionLastActive,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (rememberMe && email.isNotEmpty) {
      await _storage.setString(StorageKeys.sessionEmail, email);
    } else {
      await _storage.remove(StorageKeys.sessionEmail);
    }
  }

  /// Updates the last active timestamp for session freshness.
  Future<void> updateLastActive() async {
    await _storage.setInt(
      StorageKeys.sessionLastActive,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Clears the active session on logout.
  Future<void> clearSession() async {
    await _storage.setBool(StorageKeys.isLoggedIn, false);
    await _storage.remove(StorageKeys.currentUserId);
    await _storage.remove(StorageKeys.sessionLastActive);

    // If remember me is disabled, forget the email as well
    if (!isRememberMe) {
      await _storage.remove(StorageKeys.sessionEmail);
    }
  }
}

