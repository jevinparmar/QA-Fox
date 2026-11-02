import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../constants/storage_constants.dart';
import '../../errors/app_exception.dart';
import '../firebase/firebase_storage_service.dart';

class FileUploadService {
  final FirebaseStorageService _storageService;
  final Uuid _uuid;

  // Track if Firebase Storage is blocked by CORS or unavailable on Web
  static bool _corsOrStorageBlocked = false;
  static bool _checkedPrefs = false;

  FileUploadService(this._storageService, [Uuid? uuid])
    : _uuid = uuid ?? const Uuid();

  /// Check whether cloud storage is blocked, checking cached preferences once
  static Future<bool> _isBlocked() async {
    if (_corsOrStorageBlocked) return true;
    if (!_checkedPrefs) {
      _checkedPrefs = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('firebase_storage_cors_blocked') == true) {
          _corsOrStorageBlocked = true;
          return true;
        }
      } catch (_) {}
    }
    return _corsOrStorageBlocked;
  }

  /// Manually mark storage as blocked (e.g. on web CORS failure) and persist to disk
  static void markStorageBlocked() {
    _corsOrStorageBlocked = true;
    _checkedPrefs = true;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('firebase_storage_cors_blocked', true);
    }).catchError((_) {});
  }

  /// Whether cloud storage is currently marked as blocked by CORS/network policy
  static bool get isStorageBlocked => _corsOrStorageBlocked;

  Future<String> _generateDataUri(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  /// Uploads user avatar to Firebase Storage. If cloud storage fails, times out, or is blocked by CORS,
  /// falls back to a base64 Data URI so user avatar profile saves never fail.
  Future<String> uploadAvatar({
    required String userId,
    required XFile file,
  }) async {
    final length = await file.length();
    if (length > 10 * 1024 * 1024) {
      throw ValidationException('Profile picture must be under 10MB.');
    }

    if (kIsWeb && await _isBlocked()) {
      return _generateDataUri(file);
    }

    try {
      final ext = file.name.split('.').last.toLowerCase();
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final path =
          '${StorageConstants.avatars}/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      return await _storageService.uploadXFile(path: path, file: file);
    } catch (e) {
      markStorageBlocked();
      debugPrint(
        '[FileUploadService] Avatar cloud upload failed: $e. Falling back to data URI.',
      );
      try {
        return await _generateDataUri(file);
      } catch (fallbackError) {
        throw StorageException(
          'Unable to process profile picture. Please try another image.',
          details: fallbackError,
        );
      }
    }
  }

  /// Uploads bug report attachments to Firebase Storage with resilient fallback.
  Future<String> uploadBugAttachment({
    required String projectId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final length = await file.length();
    if (length > 50 * 1024 * 1024) {
      throw ValidationException('Attachment must be under 50MB.');
    }

    if (kIsWeb && await _isBlocked()) {
      onProgress?.call(1.0);
      return _generateDataUri(file);
    }

    try {
      final ext = file.name.split('.').last;
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final filename = '${_uuid.v4()}.$safeExt';
      final path = '${StorageConstants.bugAttachments}/$projectId/$filename';
      return await _storageService.uploadXFile(
        path: path,
        file: file,
        onProgress: onProgress,
      );
    } catch (e) {
      markStorageBlocked();
      debugPrint(
        '[FileUploadService] Bug attachment cloud upload failed: $e. Falling back to data URI.',
      );
      try {
        onProgress?.call(1.0);
        return await _generateDataUri(file);
      } catch (fallbackError) {
        throw StorageException(
          'Failed to process bug attachment. Please try again.',
          details: fallbackError,
        );
      }
    }
  }

  /// Uploads chat image/document/video attachment to Firebase Storage with resilient fallback.
  Future<String> uploadChatAttachment({
    required String chatId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final length = await file.length();
    if (length > 50 * 1024 * 1024) {
      throw ValidationException('Attachment must be under 50MB.');
    }

    if (kIsWeb && await _isBlocked()) {
      onProgress?.call(1.0);
      return _generateDataUri(file);
    }

    try {
      final ext = file.name.split('.').last;
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final filename = '${_uuid.v4()}.$safeExt';
      final path = '${StorageConstants.attachments}/$chatId/$filename';
      return await _storageService.uploadXFile(
        path: path,
        file: file,
        onProgress: onProgress,
      );
    } catch (e) {
      markStorageBlocked();
      debugPrint(
        '[FileUploadService] Chat attachment cloud upload failed: $e. Falling back to data URI.',
      );
      try {
        onProgress?.call(1.0);
        return await _generateDataUri(file);
      } catch (fallbackError) {
        throw StorageException(
          'Failed to upload attachment. Please check your connection and try again.',
          details: fallbackError,
        );
      }
    }
  }
}
