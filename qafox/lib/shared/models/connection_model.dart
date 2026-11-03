import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/app_status.dart';

class ConnectionRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? senderDesignation;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final ConnectionStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.senderDesignation,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ConnectionRequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ConnectionRequestModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderAvatar: map['senderAvatar'] as String?,
      senderDesignation: map['senderDesignation'] as String?,
      receiverId: map['receiverId'] as String? ?? '',
      receiverName: map['receiverName'] as String? ?? '',
      receiverAvatar: map['receiverAvatar'] as String?,
      status: ConnectionStatus.fromString(map['status'] as String?),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ConnectionRequestModel.empty() {
    return const ConnectionRequestModel(
      id: '',
      senderId: '',
      senderName: '',
      receiverId: '',
      receiverName: '',
      status: ConnectionStatus.pendingSent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'senderDesignation': senderDesignation,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'status': status.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
