import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String? iconUrl;
  final String platform; // Website, Android, iOS, Multiple
  final String? projectUrl;
  final String groupChatId;
  final int openBugCount;
  final int totalBugCount;
  final List<String> memberIds;
  final String creatorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProjectModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.iconUrl,
    required this.platform,
    this.projectUrl,
    required this.groupChatId,
    this.openBugCount = 0,
    this.totalBugCount = 0,
    this.memberIds = const [],
    this.creatorId = '',
    this.createdAt,
    this.updatedAt,
  });

  bool isMaster(String userId) {
    if (creatorId.isNotEmpty) return creatorId == userId;
    return memberIds.isNotEmpty && memberIds.first == userId;
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final members = List<String>.from(map['memberIds'] ?? []);
    final creator =
        map['creatorId'] as String? ??
        (members.isNotEmpty ? members.first : '');

    return ProjectModel(
      id: id,
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      iconUrl: map['iconUrl'] as String?,
      platform: map['platform'] as String? ?? 'Multiple',
      projectUrl: map['projectUrl'] as String?,
      groupChatId: map['groupChatId'] as String? ?? '',
      openBugCount: (map['openBugCount'] as num?)?.toInt() ?? 0,
      totalBugCount: (map['totalBugCount'] as num?)?.toInt() ?? 0,
      memberIds: members,
      creatorId: creator,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'platform': platform,
      'projectUrl': projectUrl,
      'groupChatId': groupChatId,
      'openBugCount': openBugCount,
      'totalBugCount': totalBugCount,
      'memberIds': memberIds,
      'creatorId': creatorId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
