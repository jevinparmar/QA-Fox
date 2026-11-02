import '../../../../core/enums/user_role.dart';
import '../../../../shared/models/organization_model.dart';

abstract class OrganizationRepository {
  Stream<List<OrganizationModel>> streamUserOrganizations(String userId);
  Future<OrganizationModel> createOrganization({
    required String name,
    String? description,
    String? logoUrl,
    required String ownerId,
    required String ownerEmail,
    required String ownerName,
  });
  Future<OrganizationModel?> getOrganization(String orgId);
  Stream<List<OrgMemberModel>> streamOrganizationMembers(String orgId);
  Future<void> inviteMember({
    required String orgId,
    required String email,
    required UserRole role,
  });
  Future<void> removeMember(String orgId, String userId);
  Future<void> updateMemberRole(String orgId, String userId, UserRole role);
}
