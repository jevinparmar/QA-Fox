class PermissionService {
  const PermissionService();

  Future<bool> requestCameraPermission() async => true;
  Future<bool> requestStoragePermission() async => true;
  Future<bool> requestNotificationPermission() async => true;
}
