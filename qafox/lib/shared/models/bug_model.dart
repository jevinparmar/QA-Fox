import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/bug_status.dart';
import '../../core/enums/bug_category.dart';
import '../../core/enums/bug_severity.dart';
import '../../core/enums/bug_priority.dart';

class BugModel {
  final String id;
  final String bugNumber; // e.g. BUG-001
  final String projectId;
  final String organizationId;
  final String groupChatId;
  final String? messageId;
  final String reporterId;
  final String reporterName;
  final String? reporterAvatar;
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeAvatar;
  final String title;
  final String description;
  final BugCategory category;
  final BugSeverity severity;
  final BugPriority priority;
  final BugStatus status;
  final String? screenName;
  final String? url;
  final String? stepsToReproduce;
  final String? expectedResult;
  final String? actualResult;
  final List<String> attachmentUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BugModel({
    required this.id,
    required this.bugNumber,
    required this.projectId,
    required this.organizationId,
    required this.groupChatId,
    this.messageId,
    required this.reporterId,
    required this.reporterName,
    this.reporterAvatar,
    this.assigneeId,
    this.assigneeName,
    this.assigneeAvatar,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.priority,
    this.status = BugStatus.open,
    this.screenName,
    this.url,
    this.stepsToReproduce,
    this.expectedResult,
    this.actualResult,
    this.attachmentUrls = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory BugModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return BugModel(
      id: id,
      bugNumber: map['bugNumber'] as String? ?? 'BUG-000',
      projectId: map['projectId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      groupChatId: map['groupChatId'] as String? ?? '',
      messageId: map['messageId'] as String?,
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      reporterAvatar: map['reporterAvatar'] as String?,
      assigneeId: map['assigneeId'] as String?,
      assigneeName: map['assigneeName'] as String?,
      assigneeAvatar: map['assigneeAvatar'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: BugCategory.fromString(map['category'] as String?),
      severity: BugSeverity.fromString(map['severity'] as String?),
      priority: BugPriority.fromString(map['priority'] as String?),
      status: BugStatus.fromString(map['status'] as String?),
      screenName: map['screenName'] as String?,
      url: map['url'] as String?,
      stepsToReproduce: map['stepsToReproduce'] as String?,
      expectedResult: map['expectedResult'] as String?,
      actualResult: map['actualResult'] as String?,
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bugNumber': bugNumber,
      'projectId': projectId,
      'organizationId': organizationId,
      'groupChatId': groupChatId,
      'messageId': messageId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterAvatar': reporterAvatar,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeAvatar': assigneeAvatar,
      'title': title,
      'description': description,
      'category': category.name,
      'severity': severity.name,
      'priority': priority.name,
      'status': status.name,
      'screenName': screenName,
      'url': url,
      'stepsToReproduce': stepsToReproduce,
      'expectedResult': expectedResult,
      'actualResult': actualResult,
      'attachmentUrls': attachmentUrls,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BugModel copyWith({
    String? assigneeId,
    String? assigneeName,
    String? assigneeAvatar,
    BugStatus? status,
    String? title,
    String? description,
    DateTime? updatedAt,
  }) {
    return BugModel(
      id: id,
      bugNumber: bugNumber,
      projectId: projectId,
      organizationId: organizationId,
      groupChatId: groupChatId,
      messageId: messageId,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterAvatar: reporterAvatar,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category,
      severity: severity,
      priority: priority,
      status: status ?? this.status,
      screenName: screenName,
      url: url,
      stepsToReproduce: stepsToReproduce,
      expectedResult: expectedResult,
      actualResult: actualResult,
      attachmentUrls: attachmentUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BugCommentModel {
  final String id;
  final String bugId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<String> attachmentUrls;
  final DateTime? createdAt;

  const BugCommentModel({
    required this.id,
    required this.bugId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.attachmentUrls = const [],
    this.createdAt,
  });

  factory BugCommentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return BugCommentModel(
      id: id,
      bugId: map['bugId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      authorAvatar: map['authorAvatar'] as String?,
      content: map['content'] as String? ?? '',
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bugId': bugId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'attachmentUrls': attachmentUrls,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class BugActivityModel {
  final String id;
  final String bugId;
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final String action; // created, statusChanged, assigned, commented
  final String? fromValue;
  final String? toValue;
  final DateTime? timestamp;

  const BugActivityModel({
    required this.id,
    required this.bugId,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    required this.action,
    this.fromValue,
    this.toValue,
    this.timestamp,
  });

  factory BugActivityModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return BugActivityModel(
      id: id,
      bugId: map['bugId'] as String? ?? '',
      actorId: map['actorId'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      actorAvatar: map['actorAvatar'] as String?,
      action: map['action'] as String? ?? '',
      fromValue: map['fromValue'] as String?,
      toValue: map['toValue'] as String?,
      timestamp: parseDate(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bugId': bugId,
      'actorId': actorId,
      'actorName': actorName,
      'actorAvatar': actorAvatar,
      'action': action,
      'fromValue': fromValue,
      'toValue': toValue,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }
}
