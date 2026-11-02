import 'local_storage_service.dart';

class SecureStorageService {
  final LocalStorageService _localStorageService;

  SecureStorageService(this._localStorageService);

  Future<void> write(String key, String value) async {
    await _localStorageService.setString('sec_$key', value);
  }

  Future<String?> read(String key) async {
    return _localStorageService.getString('sec_$key');
  }

  Future<void> delete(String key) async {
    await _localStorageService.remove('sec_$key');
  }
}
