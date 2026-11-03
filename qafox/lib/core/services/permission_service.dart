import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../storage/local_storage_service.dart';
import '../utils/logger.dart';

class PermissionService {
  final LocalStorageService? _storage;

  const PermissionService([this._storage]);

  static const String keyPermissionsRequested = 'app_permissions_requested_v1';

  /// Requests all essential app permissions (Notifications, Camera, Photos, Videos).
  Future<Map<Permission, PermissionStatus>> requestInitialAppPermissions({
    bool force = false,
  }) async {
    if (kIsWeb) return {};

    // Only prompt on first run unless forced
    if (!force && _storage != null) {
      final alreadyRequested = _storage.getBool(keyPermissionsRequested) ?? false;
      if (alreadyRequested) return {};
    }

    try {
      final permissionsToRequest = <Permission>[
        Permission.notification,
        Permission.camera,
        Permission.microphone,
      ];

      if (Platform.isAndroid) {
        permissionsToRequest.addAll([
          Permission.photos,
          Permission.videos,
          Permission.storage,
        ]);
      } else if (Platform.isIOS) {
        permissionsToRequest.add(Permission.photos);
      }

      final statuses = await permissionsToRequest.request();
      if (_storage != null) {
        await _storage.setBool(keyPermissionsRequested, true);
      }
      AppLogger.info('Initial app permissions requested: $statuses');
      return statuses;
    } catch (e) {
      AppLogger.error('Error requesting initial app permissions', e);
      return {};
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestMediaPermissions() async {
    if (kIsWeb) return true;
    try {
      if (Platform.isAndroid) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        return photos.isGranted || videos.isGranted;
      } else {
        final photos = await Permission.photos.request();
        return photos.isGranted;
      }
    } catch (_) {
      return false;
    }
  }
}
