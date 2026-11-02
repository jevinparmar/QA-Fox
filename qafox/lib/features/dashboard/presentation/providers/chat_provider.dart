import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/chat_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(firestoreServiceProvider));
});

final userChatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).streamUserChats(user.uid);
});

final userGroupChatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).streamUserGroupChats(user.uid);
});

final chatMessagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
      return ref.watch(chatRepositoryProvider).streamMessages(chatId);
    });
