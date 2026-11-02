import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../errors/app_exception.dart';
import '../../errors/error_handler.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance {
    try {
      _storage.setMaxUploadRetryTime(const Duration(seconds: 2));
      _storage.setMaxOperationRetryTime(const Duration(seconds: 2));
    } catch (_) {}
  }

  SettableMetadata _getEffectiveMetadata(XFile file, SettableMetadata? custom) {
    if (custom != null && custom.contentType != null) return custom;
    final ext = file.name.split('.').last.toLowerCase();
    String mime = 'application/octet-stream';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        mime = 'image/jpeg';
        break;
      case 'png':
        mime = 'image/png';
        break;
      case 'gif':
        mime = 'image/gif';
        break;
      case 'webp':
        mime = 'image/webp';
        break;
      case 'mp4':
        mime = 'video/mp4';
        break;
      case 'pdf':
        mime = 'application/pdf';
        break;
    }
    return SettableMetadata(
      contentType: mime,
      customMetadata: custom?.customMetadata,
    );
  }

  Future<String> uploadXFile({
    required String path,
    required XFile file,
    SettableMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final effectiveMetadata = _getEffectiveMetadata(file, metadata);
      final UploadTask uploadTask;

      if (!kIsWeb && file.path.isNotEmpty) {
        final ioFile = File(file.path);
        if (await ioFile.exists()) {
          uploadTask = ref.putFile(ioFile, effectiveMetadata);
        } else {
          final bytes = await file.readAsBytes();
          uploadTask = ref.putData(bytes, effectiveMetadata);
        }
      } else {
        final bytes = await file.readAsBytes();
        uploadTask = ref.putData(bytes, effectiveMetadata);
      }

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(
          (event) {
            if (event.totalBytes > 0) {
              final progress = event.bytesTransferred / event.totalBytes;
              onProgress(progress);
            }
          },
          onError: (_) {},
          cancelOnError: true,
        );
      }

      final timeoutDuration = kIsWeb
          ? const Duration(seconds: 2)
          : const Duration(seconds: 15);
      final snapshot = await uploadTask.timeout(
        timeoutDuration,
        onTimeout: () {
          try {
            uploadTask.cancel();
          } catch (_) {}
          throw StorageException(
            'Cloud storage upload timed out or was blocked by CORS policy.',
          );
        },
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[FirebaseStorageService] uploadXFile failed for $path: $e');
      throw StorageException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<String> uploadFile({
    required String path,
    required File file,
    SettableMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        uploadTask = ref.putFile(file, metadata);
      }

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(
          (event) {
            if (event.totalBytes > 0) {
              final progress = event.bytesTransferred / event.totalBytes;
              onProgress(progress);
            }
          },
          onError: (_) {},
          cancelOnError: true,
        );
      }

      final timeoutDuration = kIsWeb
          ? const Duration(seconds: 2)
          : const Duration(seconds: 15);
      final snapshot = await uploadTask.timeout(
        timeoutDuration,
        onTimeout: () {
          try {
            uploadTask.cancel();
          } catch (_) {}
          throw StorageException(
            'Cloud storage upload timed out or was blocked by CORS policy.',
          );
        },
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw StorageException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<String> uploadData({
    required String path,
    required Uint8List data,
    SettableMetadata? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(
          (event) {
            if (event.totalBytes > 0) {
              final progress = event.bytesTransferred / event.totalBytes;
              onProgress(progress);
            }
          },
          onError: (_) {},
          cancelOnError: true,
        );
      }

      final timeoutDuration = kIsWeb
          ? const Duration(seconds: 2)
          : const Duration(seconds: 15);
      final snapshot = await uploadTask.timeout(
        timeoutDuration,
        onTimeout: () {
          try {
            uploadTask.cancel();
          } catch (_) {}
          throw StorageException(
            'Cloud storage upload timed out or was blocked by CORS policy.',
          );
        },
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[FirebaseStorageService] uploadData failed for $path: $e');
      throw StorageException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
