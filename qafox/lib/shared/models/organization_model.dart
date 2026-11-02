import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/user_role.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String ownerId;
  final int memberCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.ownerId,
    this.memberCount = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory OrganizationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return OrganizationModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      logoUrl: map['logoUrl'] as String?,
      ownerId: map['ownerId'] as String? ?? '',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 1,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'ownerId': ownerId,
      'memberCount': memberCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class OrgMemberModel {
  final String userId;
  final String organizationId;
  final UserRole role;
  final String email;
  final String fullName;
  final String? photoUrl;
  final DateTime? joinedAt;

  const OrgMemberModel({
    required this.userId,
    required this.organizationId,
    required this.role,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.joinedAt,
  });

  factory OrgMemberModel.fromMap(Map<String, dynamic> map, String userId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return OrgMemberModel(
      userId: userId,
      organizationId: map['organizationId'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      joinedAt: parseDate(map['joinedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'organizationId': organizationId,
      'role': role.name,
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
