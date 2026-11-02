import 'package:image_picker/image_picker.dart';

import '../../../../core/enums/bug_status.dart';
import '../../../../shared/models/bug_model.dart';

abstract class BugRepository {
  Stream<List<BugModel>> streamProjectBugs(String projectId);
  Future<BugModel?> getBug(String bugId);
  Future<List<BugModel>> submitMultipleBugs({
    required String projectId,
    required String organizationId,
    required String groupChatId,
    required String reporterId,
    required String reporterName,
    String? reporterAvatar,
    required List<BugDraft> drafts,
    void Function(double overallProgress)? onProgress,
  });
  Future<void> updateBugStatus({
    required String bugId,
    required BugStatus newStatus,
    required String actorId,
    required String actorName,
    String? actorAvatar,
  });
  Future<void> assignBug({
    required String bugId,
    required String assigneeId,
    required String assigneeName,
    String? assigneeAvatar,
    required String actorId,
    required String actorName,
  });
  Stream<List<BugCommentModel>> streamComments(String bugId);
  Future<void> addComment({
    required String bugId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String content,
    List<String> attachmentUrls = const [],
  });
  Stream<List<BugActivityModel>> streamActivities(String bugId);
}

class BugDraft {
  String id;
  String title;
  String description;
  String category;
  String severity;
  String priority;
  String? screenName;
  String? url;
  String? stepsToReproduce;
  String? expectedResult;
  String? actualResult;
  List<XFile> localFiles;

  BugDraft({
    required this.id,
    this.title = '',
    this.description = '',
    this.category = 'Overall',
    this.severity = 'Medium',
    this.priority = 'Medium',
    this.screenName,
    this.url,
    this.stepsToReproduce,
    this.expectedResult,
    this.actualResult,
    List<XFile>? localFiles,
  }) : localFiles = localFiles ?? [];
}
