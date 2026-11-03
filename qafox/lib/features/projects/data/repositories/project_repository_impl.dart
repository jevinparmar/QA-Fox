import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/app_status.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/models/project_model.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final FirestoreService _firestore;
  final Uuid _uuid;

  ProjectRepositoryImpl(this._firestore, [Uuid? uuid])
    : _uuid = uuid ?? const Uuid();

  @override
  Stream<List<ProjectModel>> streamProjects(String organizationId) {
    return _firestore
        .streamCollection(
          FirestoreConstants.projects,
          queryBuilder: (q) =>
              q.where('organizationId', isEqualTo: organizationId),
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<List<ProjectModel>> streamAllUserProjects(String userId) {
    return _firestore
        .streamCollection(
          FirestoreConstants.projects,
          queryBuilder: (q) => q.where('memberIds', arrayContains: userId),
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<ProjectModel?> getProject(String projectId) async {
    final snapshot = await _firestore.getDoc(
      '${FirestoreConstants.projects}/$projectId',
    );
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ProjectModel.fromMap(snapshot.data()!, snapshot.id);
  }

  @override
  Future<ProjectModel> createProject({
    required String organizationId,
    required String name,
    String? description,
    String? iconUrl,
    required String platform,
    String? projectUrl,
    required String creatorId,
  }) async {
    final projectId = _uuid.v4();
    final groupChatId = 'chat_project_$projectId';

    final project = ProjectModel(
      id: projectId,
      organizationId: organizationId,
      name: name.trim(),
      description: description?.trim(),
      iconUrl: iconUrl,
      platform: platform,
      projectUrl: projectUrl?.trim(),
      groupChatId: groupChatId,
      openBugCount: 0,
      totalBugCount: 0,
      memberIds: [creatorId],
      creatorId: creatorId,
      createdAt: DateTime.now(),
    );

    // Create Dedicated Project Group Chat
    final groupChat = ChatModel(
      id: groupChatId,
      type: ChatType.projectGroup,
      name: name.trim(),
      iconUrl: iconUrl,
      participantIds: [creatorId],
      projectId: projectId,
      organizationId: organizationId,
      creatorId: creatorId,
      lastMessage:
          'Project group chat created. Ready for testing collaboration!',
      lastMessageSenderId: creatorId,
      lastMessageAt: DateTime.now(),
      lastMessageType: MessageType.system,
    );

    // Initial Welcome System Message
    final systemMessage = MessageModel(
      id: _uuid.v4(),
      chatId: groupChatId,
      senderId: creatorId,
      senderName: 'System',
      type: MessageType.system,
      content:
          '🚀 Project "$name" created. Testers can now report bugs directly here.',
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    final projectRef = _firestore.doc(
      '${FirestoreConstants.projects}/$projectId',
    );
    final chatRef = _firestore.doc('${FirestoreConstants.chats}/$groupChatId');
    final msgRef = _firestore.doc(
      '${FirestoreConstants.chats}/$groupChatId/${FirestoreConstants.messages}/${systemMessage.id}',
    );

    batch.set(projectRef, project.toMap());
    batch.set(chatRef, groupChat.toMap());
    batch.set(msgRef, systemMessage.toMap());
    await batch.commit();

    return project;
  }

  @override
  Future<void> updateProject(ProjectModel project) async {
    await _firestore.updateDoc(
      '${FirestoreConstants.projects}/${project.id}',
      project.toMap(),
    );
  }

  @override
  Future<void> addMemberToProject(String projectId, String userId) async {
    await addMembersToProject(projectId, [userId]);
  }

  @override
  Future<void> addMembersToProject(
    String projectId,
    List<String> userIds, {
    String? addedByName,
  }) async {
    if (userIds.isEmpty) return;
    final projRef = _firestore.doc('${FirestoreConstants.projects}/$projectId');
    final projDoc = await projRef.get();
    if (!projDoc.exists) return;

    final groupChatId = projDoc.data()?['groupChatId'] as String?;
    await projRef.set({
      'memberIds': FieldValue.arrayUnion(userIds),
    }, SetOptions(merge: true));

    if (groupChatId != null) {
      final chatRef = _firestore.doc(
        '${FirestoreConstants.chats}/$groupChatId',
      );
      await chatRef.set({
        'participantIds': FieldValue.arrayUnion(userIds),
      }, SetOptions(merge: true));
    }

    // Post announcement message as a separate operation so message rules don't block adding members
    if (groupChatId != null) {
      try {
        final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'system';
        final sysMsgId = _uuid.v4();
        final msgText = addedByName != null
            ? '👑 Group Master $addedByName added ${userIds.length} member(s) to the group.'
            : 'New members joined the group.';
        await _firestore.setDoc(
          '${FirestoreConstants.chats}/$groupChatId/${FirestoreConstants.messages}/$sysMsgId',
          {
            'id': sysMsgId,
            'chatId': groupChatId,
            'senderId': currentUid,
            'senderName': addedByName ?? 'System',
            'content': msgText,
            'type': MessageType.system.name,
            'deletedFor': <String>[],
            'isDeletedForEveryone': false,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      } catch (e) {
        AppLogger.warning('Could not post join announcement message: $e');
      }
    }
  }

  @override
  Future<void> removeMemberFromProject(String projectId, String userId) async {
    final projRef = _firestore.doc('${FirestoreConstants.projects}/$projectId');
    final projDoc = await projRef.get();
    if (!projDoc.exists) return;

    final groupChatId = projDoc.data()?['groupChatId'] as String?;
    await projRef.set({
      'memberIds': FieldValue.arrayRemove([userId]),
    }, SetOptions(merge: true));

    if (groupChatId != null) {
      final chatRef = _firestore.doc(
        '${FirestoreConstants.chats}/$groupChatId',
      );
      await chatRef.set({
        'participantIds': FieldValue.arrayRemove([userId]),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final projRef = _firestore.doc('${FirestoreConstants.projects}/$projectId');
    final projDoc = await projRef.get();
    final groupChatId = projDoc.data()?['groupChatId'] as String?;

    // 1. Delete project document
    await _firestore.deleteDoc('${FirestoreConstants.projects}/$projectId');

    // 2. Cascade delete project bugs
    try {
      final bugsSnapshot = await _firestore.getCollection(
        FirestoreConstants.bugs,
        queryBuilder: (q) => q.where('projectId', isEqualTo: projectId),
      );
      for (final doc in bugsSnapshot.docs) {
        await _firestore.deleteDoc('${FirestoreConstants.bugs}/${doc.id}');
      }
    } catch (_) {}

    // 3. Mark project group chat as archived
    if (groupChatId != null) {
      try {
        await _firestore.updateDoc('${FirestoreConstants.chats}/$groupChatId', {
          'isArchived': true,
        });
      } catch (_) {}
    }
  }
}
