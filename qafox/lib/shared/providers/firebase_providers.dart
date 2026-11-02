import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_constants.dart';
import '../../core/services/firebase/firebase_auth_service.dart';
import '../../core/services/firebase/firestore_service.dart';
import '../../core/services/firebase/firebase_storage_service.dart';
import '../../core/services/firebase/firebase_messaging_service.dart';
import '../../core/services/media/file_upload_service.dart';
import '../../core/services/media/image_picker_service.dart';
import '../../core/services/media/video_picker_service.dart';
import '../models/user_model.dart';

// Firebase SDK Singletons
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

// Core Services
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(ref.watch(firebaseAuthProvider));
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firebaseFirestoreProvider));
});

final storageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService(ref.watch(firebaseStorageProvider));
});

final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService(ref.watch(storageServiceProvider));
});

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

final videoPickerServiceProvider = Provider<VideoPickerService>((ref) {
  return VideoPickerService();
});

final messagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService();
});

// Current User State
final authStateStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateStreamProvider).value;
});

final currentUserModelStreamProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value(null);

  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamDoc('${FirestoreConstants.users}/${user.uid}').map((
    snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserModel.fromMap(snapshot.data()!, snapshot.id);
  });
});
