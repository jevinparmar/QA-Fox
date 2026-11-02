import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/app_status.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirestoreService _firestore;

  ChatRepositoryImpl(this._firestore);

  @override
  Stream<List<ChatModel>> streamUserChats(String userId) {
    return _firestore
        .streamCollection(
          FirestoreConstants.chats,
          queryBuilder: (q) => q.where('participantIds', arrayContains: userId),
        )
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .where((chat) => !chat.deletedFor.contains(userId))
              .toList();
          list.sort((a, b) {
            final timeA =
                a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB =
                b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeB.compareTo(timeA);
          });
          return list;
        });
  }

  @override
  Stream<List<ChatModel>> streamUserGroupChats(String userId) {
    return _firestore
        .streamCollection(
          FirestoreConstants.chats,
          queryBuilder: (q) => q.where('participantIds', arrayContains: userId),
        )
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .where(
                (chat) =>
                    chat.type == ChatType.projectGroup &&
                    !chat.deletedFor.contains(userId),
              )
              .toList();
          list.sort((a, b) {
            final timeA =
                a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB =
                b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeB.compareTo(timeA);
          });
          return list;
        });
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .streamCollection(
          '${FirestoreConstants.chats}/$chatId/${FirestoreConstants.messages}',
          queryBuilder: (q) =>
              q.orderBy('createdAt', descending: true).limit(100),
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final batch = _firestore.batch();
    final msgRef = _firestore.doc(
      '${FirestoreConstants.chats}/${message.chatId}/${FirestoreConstants.messages}/${message.id}',
    );
    final chatRef = _firestore.doc(
      '${FirestoreConstants.chats}/${message.chatId}',
    );

    batch.set(msgRef, message.toMap());
    batch.update(chatRef, {
      'lastMessage': message.type == MessageType.bugReport
          ? '🐛 ${message.bugData?['bugNumber'] ?? 'Bug'}: ${message.bugData?['title'] ?? message.content}'
          : message.content,
      'lastMessageSenderId': message.senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageType': message.type.name,
    });

    await batch.commit();
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.updateDoc('${FirestoreConstants.chats}/$chatId', {
        'unreadCounts.$userId': 0,
      });
    } catch (_) {}
  }

  @override
  Future<void> pinChat(String chatId, bool isPinned) async {
    await _firestore.updateDoc('${FirestoreConstants.chats}/$chatId', {
      'isPinned': isPinned,
    });
  }

  @override
  Future<void> muteChat(String chatId, bool isMuted) async {
    await _firestore.updateDoc('${FirestoreConstants.chats}/$chatId', {
      'isMuted': isMuted,
    });
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    await deleteMessageForEveryone(chatId, messageId);
  }

  @override
  Future<void> deleteMessageForMe(
    String chatId,
    String messageId,
    String userId,
  ) async {
    await _firestore.updateDoc(
      '${FirestoreConstants.chats}/$chatId/${FirestoreConstants.messages}/$messageId',
      {
        'deletedFor': FieldValue.arrayUnion([userId]),
      },
    );
  }

  @override
  Future<void> deleteMessageForEveryone(String chatId, String messageId) async {
    await _firestore.deleteDoc(
      '${FirestoreConstants.chats}/$chatId/${FirestoreConstants.messages}/$messageId',
    );
  }

  @override
  Future<void> deleteAllMessagesForMe(String chatId, String userId) async {
    final snapshot = await _firestore.getCollection(
      '${FirestoreConstants.chats}/$chatId/${FirestoreConstants.messages}',
    );
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> deleteAllMessagesForEveryone(String chatId) async {
    final snapshot = await _firestore.getCollection(
      '${FirestoreConstants.chats}/$chatId/${FirestoreConstants.messages}',
    );
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    final chatRef = _firestore.doc('${FirestoreConstants.chats}/$chatId');
    batch.update(chatRef, {
      'lastMessage': 'Chat history cleared',
      'lastMessageType': MessageType.system.name,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> deleteChatForUser(String chatId, String userId) async {
    await _firestore.updateDoc('${FirestoreConstants.chats}/$chatId', {
      'deletedFor': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> deleteMultipleChatsForUser(
    List<String> chatIds,
    String userId,
  ) async {
    final batch = _firestore.batch();
    for (final chatId in chatIds) {
      final chatRef = _firestore.doc('${FirestoreConstants.chats}/$chatId');
      batch.update(chatRef, {
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }
}
