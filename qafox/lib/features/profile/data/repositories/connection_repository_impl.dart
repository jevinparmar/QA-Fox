import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/app_status.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/models/connection_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/repositories/connection_repository.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final FirestoreService _firestore;

  ConnectionRepositoryImpl(this._firestore);

  @override
  Future<List<UserModel>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final snapshot = await _firestore
        .collection(FirestoreConstants.users)
        .limit(50)
        .get();

    final seenIds = <String>{};
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .where((user) {
          if (!seenIds.add(user.id)) return false;
          final name = user.fullName.toLowerCase();
          final username = user.username.toLowerCase();
          final email = user.email.toLowerCase();
          return name.contains(cleanQuery) ||
              username.contains(cleanQuery) ||
              email.contains(cleanQuery);
        })
        .toList();
  }

  @override
  Future<List<UserModel>> getAllUsers(String currentUserId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.users)
        .limit(100)
        .get();
    return snapshot.docs
        .where((doc) => doc.id != currentUserId)
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final users = <UserModel>[];
    for (final uid in userIds) {
      try {
        final doc = await _firestore.getDoc('${FirestoreConstants.users}/$uid');
        if (doc.exists && doc.data() != null) {
          users.add(UserModel.fromMap(doc.data()!, doc.id));
        }
      } catch (_) {}
    }
    return users;
  }

  @override
  Stream<List<ConnectionRequestModel>> streamReceivedRequests(String userId) {
    return _firestore
        .streamCollection(
          FirestoreConstants.connectionRequests,
          queryBuilder: (q) => q
              .where('receiverId', isEqualTo: userId)
              .where('status', isEqualTo: ConnectionStatus.pendingSent.name),
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<List<ConnectionRequestModel>> streamSentRequests(String userId) {
    return _firestore
        .streamCollection(
          FirestoreConstants.connectionRequests,
          queryBuilder: (q) => q
              .where('senderId', isEqualTo: userId)
              .where('status', isEqualTo: ConnectionStatus.pendingSent.name),
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<List<UserModel>> streamConnectedUsers(String userId) {
    return _firestore
        .streamCollection(
          '${FirestoreConstants.users}/$userId/${FirestoreConstants.connections}',
        )
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs.map((doc) => doc.id).toSet();

          // Also pull from root connection_requests where status is connected
          try {
            final sentReqs = await _firestore.getCollection(
              FirestoreConstants.connectionRequests,
              queryBuilder: (q) => q
                  .where('senderId', isEqualTo: userId)
                  .where('status', isEqualTo: ConnectionStatus.connected.name),
            );
            for (final d in sentReqs.docs) {
              final rId = d.data()['receiverId'] as String?;
              if (rId != null && rId != userId) userIds.add(rId);
            }

            final recvReqs = await _firestore.getCollection(
              FirestoreConstants.connectionRequests,
              queryBuilder: (q) => q
                  .where('receiverId', isEqualTo: userId)
                  .where('status', isEqualTo: ConnectionStatus.connected.name),
            );
            for (final d in recvReqs.docs) {
              final sId = d.data()['senderId'] as String?;
              if (sId != null && sId != userId) userIds.add(sId);
            }
          } catch (_) {}

          if (userIds.isEmpty) return <UserModel>[];

          final users = <UserModel>[];
          for (final id in userIds) {
            final doc = await _firestore.getDoc(
              '${FirestoreConstants.users}/$id',
            );
            if (doc.exists && doc.data() != null) {
              users.add(UserModel.fromMap(doc.data()!, doc.id));
            }
          }
          return users;
        });
  }

  @override
  Future<void> sendConnectionRequest({
    required UserModel sender,
    required UserModel receiver,
  }) async {
    final requestId = 'req_${sender.id}_${receiver.id}';
    final request = ConnectionRequestModel(
      id: requestId,
      senderId: sender.id,
      senderName: sender.fullName,
      senderAvatar: sender.photoUrl,
      senderDesignation: sender.designation,
      receiverId: receiver.id,
      receiverName: receiver.fullName,
      receiverAvatar: receiver.photoUrl,
      status: ConnectionStatus.pendingSent,
      createdAt: DateTime.now(),
    );

    await _firestore.setDoc(
      '${FirestoreConstants.connectionRequests}/$requestId',
      request.toMap(),
    );
  }

  @override
  Future<void> acceptConnectionRequest(ConnectionRequestModel request) async {
    // 1. Update request status to connected first
    await _firestore.updateDoc(
      '${FirestoreConstants.connectionRequests}/${request.id}',
      {
        'status': ConnectionStatus.connected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // 2. Add to receiver's own connections subcollection (always succeeds for current user)
    try {
      final connReceiver = _firestore.doc(
        '${FirestoreConstants.users}/${request.receiverId}/${FirestoreConstants.connections}/${request.senderId}',
      );
      await connReceiver.set({'connectedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Receiver connection write error: $e');
    }

    // 3. Add to sender's connections subcollection
    try {
      final connSender = _firestore.doc(
        '${FirestoreConstants.users}/${request.senderId}/${FirestoreConstants.connections}/${request.receiverId}',
      );
      await connSender.set({'connectedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Sender connection write error: $e');
    }

    // 4. Create or prepare individual chat between them
    try {
      await getOrCreateIndividualChat(
        request.senderId,
        request.receiverId,
        request.senderName,
        request.receiverName,
      );
    } catch (e) {
      debugPrint('Individual chat create error: $e');
    }
  }

  @override
  Future<void> declineConnectionRequest(String requestId) async {
    await _firestore.deleteDoc(
      '${FirestoreConstants.connectionRequests}/$requestId',
    );
  }

  @override
  Future<void> cancelSentRequest(String requestId) async {
    await _firestore.deleteDoc(
      '${FirestoreConstants.connectionRequests}/$requestId',
    );
  }

  @override
  Future<void> removeConnection(
    String currentUserId,
    String targetUserId,
  ) async {
    final batch = _firestore.batch();
    final connA = _firestore.doc(
      '${FirestoreConstants.users}/$currentUserId/${FirestoreConstants.connections}/$targetUserId',
    );
    final connB = _firestore.doc(
      '${FirestoreConstants.users}/$targetUserId/${FirestoreConstants.connections}/$currentUserId',
    );
    batch.delete(connA);
    batch.delete(connB);
    await batch.commit();
  }

  @override
  Future<String> getOrCreateIndividualChat(
    String userAId,
    String userBId,
    String userAName,
    String userBName,
  ) async {
    // Generate deterministic chat ID
    final sortedIds = [userAId, userBId]..sort();
    final chatId = 'chat_ind_${sortedIds[0]}_${sortedIds[1]}';

    final doc = await _firestore.getDoc('${FirestoreConstants.chats}/$chatId');
    if (!doc.exists) {
      final chat = ChatModel(
        id: chatId,
        type: ChatType.individual,
        name: '$userAName & $userBName',
        participantIds: sortedIds,
        lastMessage: 'Connected! Start chatting and sharing testing notes.',
        lastMessageAt: DateTime.now(),
        lastMessageType: MessageType.system,
      );
      await _firestore.setDoc(
        '${FirestoreConstants.chats}/$chatId',
        chat.toMap(),
      );
    }
    return chatId;
  }
}
