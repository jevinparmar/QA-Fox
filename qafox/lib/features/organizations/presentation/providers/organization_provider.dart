import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/organization_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../domain/repositories/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl(ref.watch(firestoreServiceProvider));
});

final userOrganizationsProvider = StreamProvider<List<OrganizationModel>>((
  ref,
) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref
      .watch(organizationRepositoryProvider)
      .streamUserOrganizations(user.uid);
});

class SelectedOrgIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? orgId) => state = orgId;
}

final selectedOrgIdProvider = NotifierProvider<SelectedOrgIdNotifier, String?>(
  SelectedOrgIdNotifier.new,
);

final selectedOrganizationProvider = FutureProvider<OrganizationModel?>((
  ref,
) async {
  final orgId = ref.watch(selectedOrgIdProvider);
  if (orgId == null) return null;
  return ref.watch(organizationRepositoryProvider).getOrganization(orgId);
});

final orgMembersStreamProvider =
    StreamProvider.family<List<OrgMemberModel>, String>((ref, orgId) {
      return ref
          .watch(organizationRepositoryProvider)
          .streamOrganizationMembers(orgId);
    });
