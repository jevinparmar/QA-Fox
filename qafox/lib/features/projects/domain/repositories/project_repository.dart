import '../../../../shared/models/project_model.dart';

abstract class ProjectRepository {
  Stream<List<ProjectModel>> streamProjects(String organizationId);
  Stream<List<ProjectModel>> streamAllUserProjects(String userId);
  Future<ProjectModel?> getProject(String projectId);
  Future<ProjectModel> createProject({
    required String organizationId,
    required String name,
    String? description,
    String? iconUrl,
    required String platform,
    String? projectUrl,
    required String creatorId,
  });
  Future<void> updateProject(ProjectModel project);
  Future<void> addMemberToProject(String projectId, String userId);
  Future<void> addMembersToProject(
    String projectId,
    List<String> userIds, {
    String? addedByName,
  });
  Future<void> removeMemberFromProject(String projectId, String userId);
  Future<void> deleteProject(String projectId);
}
