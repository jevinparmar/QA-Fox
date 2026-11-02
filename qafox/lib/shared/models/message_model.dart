import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/app_status.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? mediaName;
  final int? mediaSize;
  final String? bugId;
  final Map<String, dynamic>? bugData;
  final String? replyToId;
  final String? replyToPreview;
  final List<String> readBy;
  final List<String> deletedFor;
  final bool isDeletedForEveryone;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.type = MessageType.text,
    required this.content,
    this.mediaUrl,
    this.mediaName,
    this.mediaSize,
    this.bugId,
    this.bugData,
    this.replyToId,
    this.replyToPreview,
    this.readBy = const [],
    this.deletedFor = const [],
    this.isDeletedForEveryone = false,
    this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return MessageModel(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderAvatar: map['senderAvatar'] as String?,
      type: MessageType.fromString(map['type'] as String?),
      content: map['content'] as String? ?? '',
      mediaUrl: map['mediaUrl'] as String?,
      mediaName: map['mediaName'] as String?,
      mediaSize: (map['mediaSize'] as num?)?.toInt(),
      bugId: map['bugId'] as String?,
      bugData: map['bugData'] as Map<String, dynamic>?,
      replyToId: map['replyToId'] as String?,
      replyToPreview: map['replyToPreview'] as String?,
      readBy: List<String>.from(map['readBy'] ?? []),
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      isDeletedForEveryone: map['isDeletedForEveryone'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaName': mediaName,
      'mediaSize': mediaSize,
      'bugId': bugId,
      'bugData': bugData,
      'replyToId': replyToId,
      'replyToPreview': replyToPreview,
      'readBy': readBy,
      'deletedFor': deletedFor,
      'isDeletedForEveryone': isDeletedForEveryone,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
