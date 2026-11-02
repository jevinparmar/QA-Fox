import 'package:firebase_auth/firebase_auth.dart';

import '../../errors/app_exception.dart';
import '../../errors/error_handler.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthService([FirebaseAuth? firebaseAuth])
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw AuthException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw AuthException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw AuthException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    } catch (e) {
      throw AuthException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }

  Future<void> updatePhotoURL(String photoURL) async {
    if (!photoURL.startsWith('http://') && !photoURL.startsWith('https://')) {
      return;
    }
    try {
      await _firebaseAuth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw AuthException(ErrorHandler.getFriendlyMessage(e), details: e);
    }
  }
}
