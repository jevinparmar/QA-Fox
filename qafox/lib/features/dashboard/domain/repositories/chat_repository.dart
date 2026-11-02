import '../../../../shared/models/chat_model.dart';
import '../../../../shared/models/message_model.dart';

abstract class ChatRepository {
  Stream<List<ChatModel>> streamUserChats(String userId);
  Stream<List<ChatModel>> streamUserGroupChats(String userId);
  Stream<List<MessageModel>> streamMessages(String chatId);
  Future<void> sendMessage(MessageModel message);
  Future<void> markChatAsRead(String chatId, String userId);
  Future<void> pinChat(String chatId, bool isPinned);
  Future<void> muteChat(String chatId, bool isMuted);
  Future<void> deleteMessage(String chatId, String messageId);
  Future<void> deleteMessageForMe(
    String chatId,
    String messageId,
    String userId,
  );
  Future<void> deleteMessageForEveryone(String chatId, String messageId);
  Future<void> deleteAllMessagesForMe(String chatId, String userId);
  Future<void> deleteAllMessagesForEveryone(String chatId);
  Future<void> deleteChatForUser(String chatId, String userId);
  Future<void> deleteMultipleChatsForUser(List<String> chatIds, String userId);
}
