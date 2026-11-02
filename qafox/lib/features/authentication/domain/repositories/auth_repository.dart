import 'package:firebase_auth/firebase_auth.dart';

import '../../../../shared/models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentFirebaseUser;
  Future<UserModel?> getCurrentUserProfile();
  Future<UserModel> signInWithEmailPassword(String email, String password);
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> updateUserProfile(UserModel user);
  Future<void> updateOnlineStatus(bool isOnline);
}
