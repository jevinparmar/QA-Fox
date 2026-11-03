import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'message', 'connection_request', 'bug', 'system'
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    final createdVal = map['createdAt'];
    if (createdVal is Timestamp) {
      parsedDate = createdVal.toDate();
    } else if (createdVal is String) {
      parsedDate = DateTime.tryParse(createdVal) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AppNotificationModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'system',
      targetId: map['targetId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parsedDate,
    );
  }
}

