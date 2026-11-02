import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService authService;
  final FirestoreService firestoreService;

  AuthRepositoryImpl({
    required this.authService,
    required this.firestoreService,
  });

  FirebaseAuthService get _authService => authService;
  FirestoreService get _firestoreService => firestoreService;

  @override
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  @override
  User? get currentFirebaseUser => _authService.currentUser;

  @override
  Future<UserModel?> getCurrentUserProfile() async {
    final uid = _authService.currentUserId;
    if (uid == null) return null;

    final snapshot = await _firestoreService.getDoc(
      '${FirestoreConstants.users}/$uid',
    );
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserModel.fromMap(snapshot.data()!, snapshot.id);
  }

  @override
  Future<UserModel> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final cred = await _authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;

    // Fetch user profile from Firestore
    final doc = await _firestoreService.getDoc(
      '${FirestoreConstants.users}/${user.uid}',
    );
    if (doc.exists && doc.data() != null) {
      await updateOnlineStatus(true);
      return UserModel.fromMap(doc.data()!, doc.id);
    }

    // If profile document missing, create fallback
    final newUser = UserModel(
      id: user.uid,
      email: user.email ?? email,
      fullName: user.displayName ?? email.split('@').first,
      username: email.split('@').first,
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _firestoreService.setDoc(
      '${FirestoreConstants.users}/${user.uid}',
      newUser.toMap(),
    );
    return newUser;
  }

  @override
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    final cred = await _authService.createUserWithEmailPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    await _authService.updateDisplayName(fullName);

    final username = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    final newUser = UserModel(
      id: user.uid,
      email: email.trim(),
      fullName: fullName.trim(),
      username: username,
      phoneNumber: phoneNumber?.trim(),
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _firestoreService.setDoc(
      '${FirestoreConstants.users}/${user.uid}',
      newUser.toMap(),
    );
    return newUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() async {
    await updateOnlineStatus(false);
    await _authService.signOut();
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    await _firestoreService.setDoc(
      '${FirestoreConstants.users}/${user.id}',
      user.toMap(),
      merge: true,
    );
    if (user.fullName.isNotEmpty) {
      try {
        await _authService.updateDisplayName(user.fullName);
      } catch (e) {
        debugPrint('[AuthRepository] updateDisplayName warning: $e');
      }
    }
    final photo = user.photoUrl;
    if (photo != null &&
        (photo.startsWith('http://') || photo.startsWith('https://')) &&
        photo.length < 2000) {
      try {
        await _authService.updatePhotoURL(photo);
      } catch (e) {
        debugPrint('[AuthRepository] updatePhotoURL warning: $e');
      }
    }
  }

  @override
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _authService.currentUserId;
    if (uid != null) {
      try {
        await _firestoreService.updateDoc('${FirestoreConstants.users}/$uid', {
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }
}
