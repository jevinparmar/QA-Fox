import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/app_status.dart';

class ChatModel {
  final String id;
  final ChatType type;
  final String name;
  final String? iconUrl;
  final List<String> participantIds;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final MessageType lastMessageType;
  final Map<String, int> unreadCounts;
  final String? projectId;
  final String? organizationId;
  final String? creatorId;
  final bool isPinned;
  final bool isMuted;
  final List<String> deletedFor;

  const ChatModel({
    required this.id,
    required this.type,
    required this.name,
    this.iconUrl,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.lastMessageType = MessageType.text,
    this.unreadCounts = const {},
    this.projectId,
    this.organizationId,
    this.creatorId,
    this.isPinned = false,
    this.isMuted = false,
    this.deletedFor = const [],
  });

  bool isMaster(String userId) {
    if (creatorId != null && creatorId!.isNotEmpty) return creatorId == userId;
    return participantIds.isNotEmpty && participantIds.first == userId;
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawUnread = map['unreadCounts'] as Map<String, dynamic>? ?? {};
    final unread = rawUnread.map((k, v) => MapEntry(k, (v as num).toInt()));
    final participants = List<String>.from(map['participantIds'] ?? []);
    final creator =
        map['creatorId'] as String? ??
        (participants.isNotEmpty ? participants.first : null);
    final deletedFor = List<String>.from(map['deletedFor'] ?? []);

    return ChatModel(
      id: id,
      type: ChatType.fromString(map['type'] as String?),
      name: map['name'] as String? ?? '',
      iconUrl: map['iconUrl'] as String?,
      participantIds: participants,
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageAt: parseDate(map['lastMessageAt']),
      lastMessageType: MessageType.fromString(
        map['lastMessageType'] as String?,
      ),
      unreadCounts: unread,
      projectId: map['projectId'] as String?,
      organizationId: map['organizationId'] as String?,
      creatorId: creator,
      isPinned: map['isPinned'] as bool? ?? false,
      isMuted: map['isMuted'] as bool? ?? false,
      deletedFor: deletedFor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'iconUrl': iconUrl,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : FieldValue.serverTimestamp(),
      'lastMessageType': lastMessageType.name,
      'unreadCounts': unreadCounts,
      'projectId': projectId,
      'organizationId': organizationId,
      'creatorId': creatorId,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'deletedFor': deletedFor,
    };
  }
}
