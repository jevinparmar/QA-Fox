import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_constants.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/utils/logger.dart';
import '../models/app_notification_model.dart';
import 'firebase_providers.dart';
import 'storage_providers.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService(ref.watch(localStorageServiceProvider));
});

/// Streams notifications for the current user from Firestore
final userNotificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotificationModel>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreServiceProvider);
  return firestore
      .streamCollection(
        FirestoreConstants.notifications,
        queryBuilder: (q) => q
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(50),
      )
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
            .toList();
      });
});

/// Real-time service to watch incoming messages & requests and trigger notifications
class NotificationWatcher {
  final Ref _ref;
  StreamSubscription? _requestsSub;
  StreamSubscription? _chatsSub;
  final Set<String> _seenRequestIds = {};
  final Map<String, String> _lastSeenMessageIdPerChat = {};
  bool _isInitialized = false;

  NotificationWatcher(this._ref);

  void startListening() {
    if (_isInitialized) return;
    _isInitialized = true;

    final currentUid = _ref.read(authServiceProvider).currentUserId;
    if (currentUid == null) return;

    final firestore = _ref.read(firestoreServiceProvider);
    final localNotifier = _ref.read(localNotificationServiceProvider);

    // 1. Watch incoming connection requests
    _requestsSub = firestore
        .streamCollection(
          FirestoreConstants.connectionRequests,
          queryBuilder: (q) => q
              .where('receiverId', isEqualTo: currentUid)
              .where('status', isEqualTo: 'pendingSent'),
        )
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final docId = change.doc.id;
              if (!_seenRequestIds.contains(docId)) {
                _seenRequestIds.add(docId);
                // Avoid notifying on historical records when first opening stream
                if (snapshot.docChanges.length == 1) {
                  final data = change.doc.data();
                  final senderName = data?['senderName'] as String? ?? 'Someone';
                  localNotifier.showNotification(
                    id: docId.hashCode,
                    title: 'New Connection Request',
                    body: '$senderName sent you a collaborator connection request!',
                    payload: '/search/requests',
                  );

                  // Persist to in-app notifications
                  _createInAppNotification(
                    userId: currentUid,
                    title: 'New Connection Request',
                    body: '$senderName wants to collaborate with you.',
                    type: 'connection_request',
                    targetId: docId,
                  );
                }
              }
            }
          }
        });

    // 2. Watch chats where user is a participant
    _chatsSub = firestore
        .streamCollection(
          FirestoreConstants.chats,
          queryBuilder: (q) => q.where('participantIds', arrayContains: currentUid),
        )
        .listen((snapshot) {
          for (final chatDoc in snapshot.docs) {
            final chatId = chatDoc.id;
            final data = chatDoc.data();
            final lastMsg = data['lastMessage'] as String?;
            final lastMsgAt = data['lastMessageAt'];
            final chatName = data['name'] as String? ?? 'New Message';

            if (lastMsg != null && lastMsg.isNotEmpty && lastMsgAt != null) {
              final compositeKey = '$chatId:$lastMsg';
              if (!_lastSeenMessageIdPerChat.containsKey(chatId)) {
                _lastSeenMessageIdPerChat[chatId] = compositeKey;
              } else if (_lastSeenMessageIdPerChat[chatId] != compositeKey) {
                _lastSeenMessageIdPerChat[chatId] = compositeKey;
                // If it wasn't sent by current user
                final lastSenderId = data['lastSenderId'] as String?;
                if (lastSenderId != null && lastSenderId != currentUid) {
                  localNotifier.showNotification(
                    id: chatId.hashCode,
                    title: chatName,
                    body: lastMsg,
                    payload: '/chat/$chatId',
                  );

                  _createInAppNotification(
                    userId: currentUid,
                    title: chatName,
                    body: lastMsg,
                    type: 'message',
                    targetId: chatId,
                  );
                }
              }
            }
          }
        });

    AppLogger.info('NotificationWatcher started for user: $currentUid');
  }

  Future<void> _createInAppNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? targetId,
  }) async {
    try {
      final firestore = _ref.read(firestoreServiceProvider);
      final notifId = FirebaseFirestore.instance.collection(FirestoreConstants.notifications).doc().id;
      final notif = AppNotificationModel(
        id: notifId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        targetId: targetId,
        createdAt: DateTime.now(),
      );
      await firestore.setDoc('${FirestoreConstants.notifications}/$notifId', notif.toMap());
    } catch (e) {
      AppLogger.warning('Could not record in-app notification: $e');
    }
  }

  void dispose() {
    _requestsSub?.cancel();
    _chatsSub?.cancel();
    _isInitialized = false;
  }
}

final notificationWatcherProvider = Provider<NotificationWatcher>((ref) {
  final watcher = NotificationWatcher(ref);
  ref.onDispose(watcher.dispose);
  return watcher;
});

