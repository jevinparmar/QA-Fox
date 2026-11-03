import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/providers/storage_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authService: ref.watch(authServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return ref.watch(authRepositoryProvider).getCurrentUserProfile();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref
          .read(authRepositoryProvider)
          .signInWithEmailPassword(email, password);
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref
          .read(authRepositoryProvider)
          .registerWithEmailPassword(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber,
          );
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updateUserProfile(updatedUser);
      return updatedUser;
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(sessionServiceProvider).clearSession();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(AuthController.new);
