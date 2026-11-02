import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../profile/presentation/providers/connection_provider.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/repositories/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(ref.watch(firestoreServiceProvider));
});

final projectsByOrgStreamProvider =
    StreamProvider.family<List<ProjectModel>, String>((ref, orgId) {
      return ref.watch(projectRepositoryProvider).streamProjects(orgId);
    });

final allUserProjectsStreamProvider = StreamProvider<List<ProjectModel>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(projectRepositoryProvider).streamAllUserProjects(user.uid);
});

final projectDetailsProvider = FutureProvider.family<ProjectModel?, String>((
  ref,
  projectId,
) {
  return ref.watch(projectRepositoryProvider).getProject(projectId);
});

final projectStreamProvider = StreamProvider.family<ProjectModel?, String>((
  ref,
  projectId,
) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamDoc('${FirestoreConstants.projects}/$projectId').map((
    snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ProjectModel.fromMap(snapshot.data()!, snapshot.id);
  });
});

final projectMembersProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  projectId,
) async {
  final project = ref.watch(projectStreamProvider(projectId)).value;
  if (project == null || project.memberIds.isEmpty) return <UserModel>[];
  return ref
      .watch(connectionRepositoryProvider)
      .getUsersByIds(project.memberIds);
});
