import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/connection_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../domain/repositories/connection_repository.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepositoryImpl(ref.watch(firestoreServiceProvider));
});

final receivedRequestsStreamProvider =
    StreamProvider<List<ConnectionRequestModel>>((ref) {
      final user = ref.watch(currentFirebaseUserProvider);
      if (user == null) return Stream.value([]);
      return ref
          .watch(connectionRepositoryProvider)
          .streamReceivedRequests(user.uid);
    });

final sentRequestsStreamProvider = StreamProvider<List<ConnectionRequestModel>>(
  (ref) {
    final user = ref.watch(currentFirebaseUserProvider);
    if (user == null) return Stream.value([]);
    return ref.watch(connectionRepositoryProvider).streamSentRequests(user.uid);
  },
);

final connectedUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(connectionRepositoryProvider).streamConnectedUsers(user.uid);
});
