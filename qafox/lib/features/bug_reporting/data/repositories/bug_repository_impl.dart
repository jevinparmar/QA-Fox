import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/app_status.dart';
import '../../../../core/enums/bug_status.dart';
import '../../../../core/enums/bug_category.dart';
import '../../../../core/enums/bug_severity.dart';
import '../../../../core/enums/bug_priority.dart';
import '../../../../core/services/firebase/firestore_service.dart';
import '../../../../core/services/media/file_upload_service.dart';
import '../../../../shared/models/bug_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../domain/repositories/bug_repository.dart';

class BugRepositoryImpl implements BugRepository {
  final FirestoreService firestore;
  final FileUploadService fileUploadService;
  final Uuid _uuid;

  BugRepositoryImpl({
    required this.firestore,
    required this.fileUploadService,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  FirestoreService get _firestore => firestore;
  FileUploadService get _fileUploadService => fileUploadService;

  @override
  Stream<List<BugModel>> streamProjectBugs(String projectId) {
    return _firestore
        .streamCollection(
          FirestoreConstants.bugs,
          queryBuilder: (q) => q.where('projectId', isEqualTo: projectId),
        )
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BugModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            final timeA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeB.compareTo(timeA);
          });
          return list;
        });
  }

  @override
  Future<BugModel?> getBug(String bugId) async {
    final snapshot = await _firestore.getDoc(
      '${FirestoreConstants.bugs}/$bugId',
    );
    if (!snapshot.exists || snapshot.data() == null) return null;
    return BugModel.fromMap(snapshot.data()!, snapshot.id);
  }

  @override
  Future<List<BugModel>> submitMultipleBugs({
    required String projectId,
    required String organizationId,
    required String groupChatId,
    required String reporterId,
    required String reporterName,
    String? reporterAvatar,
    required List<BugDraft> drafts,
    void Function(double overallProgress)? onProgress,
  }) async {
    if (drafts.isEmpty) return [];

    // 1. Get current project total bug count to generate BUG-001 sequential numbers
    final projRef = _firestore.doc('${FirestoreConstants.projects}/$projectId');
    final projDoc = await projRef.get();
    int currentTotal = (projDoc.data()?['totalBugCount'] as num?)?.toInt() ?? 0;

    final submittedBugs = <BugModel>[];
    final totalSteps = drafts.length * 2;
    var currentStep = 0;

    final batch = _firestore.batch();

    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      currentTotal++;
      final bugNumber = 'BUG-${currentTotal.toString().padLeft(3, '0')}';
      final bugId = _uuid.v4();
      final messageId = _uuid.v4();

      // Upload local attachments
      final attachmentUrls = <String>[];
      for (final file in draft.localFiles) {
        try {
          final url = await _fileUploadService.uploadBugAttachment(
            projectId: projectId,
            file: file,
          );
          attachmentUrls.add(url);
        } catch (e) {
          debugPrint(
            '[BugRepository] Bug attachment cloud upload failed: $e, falling back to data URI',
          );
          try {
            final bytes = await file.readAsBytes();
            final ext = file.name.split('.').last.toLowerCase();
            final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
            attachmentUrls.add('data:$mime;base64,${base64Encode(bytes)}');
          } catch (readError) {
            debugPrint(
              '[BugRepository] Failed to read attachment bytes: $readError',
            );
          }
        }
      }

      currentStep++;
      onProgress?.call(currentStep / totalSteps);

      final bug = BugModel(
        id: bugId,
        bugNumber: bugNumber,
        projectId: projectId,
        organizationId: organizationId,
        groupChatId: groupChatId,
        messageId: messageId,
        reporterId: reporterId,
        reporterName: reporterName,
        reporterAvatar: reporterAvatar,
        title: draft.title.trim(),
        description: draft.description.trim(),
        category: BugCategory.fromString(draft.category),
        severity: BugSeverity.fromString(draft.severity),
        priority: BugPriority.fromString(draft.priority),
        status: BugStatus.open,
        screenName: draft.screenName?.trim(),
        url: draft.url?.trim(),
        stepsToReproduce: draft.stepsToReproduce?.trim(),
        expectedResult: draft.expectedResult?.trim(),
        actualResult: draft.actualResult?.trim(),
        attachmentUrls: attachmentUrls,
        createdAt: DateTime.now(),
      );

      // Create Structured Chat Message
      final previewBugMap = bug.toMap();
      if (attachmentUrls.isNotEmpty) {
        previewBugMap['attachmentUrls'] = [attachmentUrls.first];
      }

      final message = MessageModel(
        id: messageId,
        chatId: groupChatId,
        senderId: reporterId,
        senderName: reporterName,
        senderAvatar: reporterAvatar,
        type: MessageType.bugReport,
        content: draft.title.trim(),
        bugId: bugId,
        bugData: previewBugMap,
        createdAt: DateTime.now(),
      );

      // Initial Activity Record
      final activityId = _uuid.v4();
      final activity = BugActivityModel(
        id: activityId,
        bugId: bugId,
        actorId: reporterId,
        actorName: reporterName,
        actorAvatar: reporterAvatar,
        action: 'created',
        toValue: 'Open',
        timestamp: DateTime.now(),
      );

      // Add to Firestore Batch
      final bugRef = _firestore.doc('${FirestoreConstants.bugs}/$bugId');
      final msgRef = _firestore.doc(
        '${FirestoreConstants.chats}/$groupChatId/${FirestoreConstants.messages}/$messageId',
      );
      final actRef = _firestore.doc(
        '${FirestoreConstants.bugs}/$bugId/${FirestoreConstants.activities}/$activityId',
      );

      batch.set(bugRef, bug.toMap());
      batch.set(msgRef, message.toMap());
      batch.set(actRef, activity.toMap());

      submittedBugs.add(bug);
    }

    // Update Project Counters
    batch.update(projRef, {
      'totalBugCount': FieldValue.increment(drafts.length),
      'openBugCount': FieldValue.increment(drafts.length),
    });

    // Update Chat's last message
    final lastBug = submittedBugs.last;
    final chatRef = _firestore.doc('${FirestoreConstants.chats}/$groupChatId');
    batch.update(chatRef, {
      'lastMessage': '🐛 ${lastBug.bugNumber}: ${lastBug.title}',
      'lastMessageSenderId': reporterId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageType': MessageType.bugReport.name,
    });

    await batch.commit();

    onProgress?.call(1.0);
    return submittedBugs;
  }

  @override
  Future<void> updateBugStatus({
    required String bugId,
    required BugStatus newStatus,
    required String actorId,
    required String actorName,
    String? actorAvatar,
  }) async {
    final bugDoc = await _firestore.getDoc('${FirestoreConstants.bugs}/$bugId');
    if (!bugDoc.exists) return;

    final oldStatusStr = bugDoc.data()?['status'] as String? ?? 'open';
    final oldStatus = BugStatus.fromString(oldStatusStr);
    final projectId = bugDoc.data()?['projectId'] as String?;
    final groupChatId = bugDoc.data()?['groupChatId'] as String?;
    final bugNumber = bugDoc.data()?['bugNumber'] as String? ?? 'Bug';

    final batch = _firestore.batch();
    final bugRef = _firestore.doc('${FirestoreConstants.bugs}/$bugId');

    batch.update(bugRef, {
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Activity log
    final actId = _uuid.v4();
    final actRef = _firestore.doc(
      '${FirestoreConstants.bugs}/$bugId/${FirestoreConstants.activities}/$actId',
    );
    final activity = BugActivityModel(
      id: actId,
      bugId: bugId,
      actorId: actorId,
      actorName: actorName,
      actorAvatar: actorAvatar,
      action: 'statusChanged',
      fromValue: oldStatus.label,
      toValue: newStatus.label,
      timestamp: DateTime.now(),
    );
    batch.set(actRef, activity.toMap());

    // Send status change system message to group chat
    if (groupChatId != null) {
      final msgId = _uuid.v4();
      final msgRef = _firestore.doc(
        '${FirestoreConstants.chats}/$groupChatId/${FirestoreConstants.messages}/$msgId',
      );
      final sysMsg = MessageModel(
        id: msgId,
        chatId: groupChatId,
        senderId: actorId,
        senderName: actorName,
        type: MessageType.system,
        content: '$actorName changed $bugNumber status to ${newStatus.label}',
        bugId: bugId,
        createdAt: DateTime.now(),
      );
      batch.set(msgRef, sysMsg.toMap());
    }

    // Update project openBugCount if transitioned between open and resolved
    if (projectId != null) {
      final wasOpen = oldStatus.isOpen;
      final isNowOpen = newStatus.isOpen;
      if (wasOpen && !isNowOpen) {
        batch.update(
          _firestore.doc('${FirestoreConstants.projects}/$projectId'),
          {'openBugCount': FieldValue.increment(-1)},
        );
      } else if (!wasOpen && isNowOpen) {
        batch.update(
          _firestore.doc('${FirestoreConstants.projects}/$projectId'),
          {'openBugCount': FieldValue.increment(1)},
        );
      }
    }

    await batch.commit();
  }

  @override
  Future<void> assignBug({
    required String bugId,
    required String assigneeId,
    required String assigneeName,
    String? assigneeAvatar,
    required String actorId,
    required String actorName,
  }) async {
    final bugDoc = await _firestore.getDoc('${FirestoreConstants.bugs}/$bugId');
    if (!bugDoc.exists) return;

    final groupChatId = bugDoc.data()?['groupChatId'] as String?;
    final bugNumber = bugDoc.data()?['bugNumber'] as String? ?? 'Bug';

    final batch = _firestore.batch();
    final bugRef = _firestore.doc('${FirestoreConstants.bugs}/$bugId');

    batch.update(bugRef, {
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeAvatar': assigneeAvatar,
      'status': BugStatus.assigned.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final actId = _uuid.v4();
    final actRef = _firestore.doc(
      '${FirestoreConstants.bugs}/$bugId/${FirestoreConstants.activities}/$actId',
    );
    final activity = BugActivityModel(
      id: actId,
      bugId: bugId,
      actorId: actorId,
      actorName: actorName,
      action: 'assigned',
      toValue: assigneeName,
      timestamp: DateTime.now(),
    );
    batch.set(actRef, activity.toMap());

    // System message to group chat
    if (groupChatId != null) {
      final msgId = _uuid.v4();
      final msgRef = _firestore.doc(
        '${FirestoreConstants.chats}/$groupChatId/${FirestoreConstants.messages}/$msgId',
      );
      final sysMsg = MessageModel(
        id: msgId,
        chatId: groupChatId,
        senderId: actorId,
        senderName: actorName,
        type: MessageType.system,
        content: '$actorName assigned $bugNumber to $assigneeName',
        bugId: bugId,
        createdAt: DateTime.now(),
      );
      batch.set(msgRef, sysMsg.toMap());
    }

    await batch.commit();
  }

  @override
  Stream<List<BugCommentModel>> streamComments(String bugId) {
    return _firestore
        .streamCollection(
          '${FirestoreConstants.bugs}/$bugId/${FirestoreConstants.comments}',
          queryBuilder: (q) => q.orderBy('createdAt', descending: false),
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BugCommentModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> addComment({
    required String bugId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String content,
    List<String> attachmentUrls = const [],
  }) async {
    final commentId = _uuid.v4();
    final comment = BugCommentModel(
      id: commentId,
      bugId: bugId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content.trim(),
      attachmentUrls: attachmentUrls,
      createdAt: DateTime.now(),
    );

    final actId = _uuid.v4();
    final activity = BugActivityModel(
      id: actId,
      bugId: bugId,
      actorId: authorId,
      actorName: authorName,
      actorAvatar: authorAvatar,
      action: 'commentAdded',
      toValue: content.trim(),
      timestamp: DateTime.now(),
    );

    final batch = _firestore.batch();
    final commentRef = _firestore.doc(
      '${FirestoreConstants.bugs}/$bugId/${FirestoreConstants.comments}/$commentId',
    );
    final actRef = _firestore.doc(
      '${FirestoreConstants.bugs}/$bugId/${FirestoreConstants.activities}/$actId',
    );
    final bugRef = _firestore.doc('${FirestoreConstants.bugs}/$bugId');

    batch.set(commentRef, comment.toMap());
    batch.set(actRef, activity.toMap());
    batch.update(bugRef, {'updatedAt': FieldValue.serverTimestamp()});

    await batch.commit();
  }

  @override
  Stream<List<BugActivityModel>> streamActivities(String bugId) {
    return _firestore
        .streamCollection(
          '${FirestoreConstants.bugs}/$bugId/${FirestoreConstants.activities}',
          queryBuilder: (q) => q.orderBy('timestamp', descending: true),
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BugActivityModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }
}
