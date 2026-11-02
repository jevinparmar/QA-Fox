import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/bug_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/bug_repository_impl.dart';
import '../../domain/repositories/bug_repository.dart';

final bugRepositoryProvider = Provider<BugRepository>((ref) {
  return BugRepositoryImpl(
    firestore: ref.watch(firestoreServiceProvider),
    fileUploadService: ref.watch(fileUploadServiceProvider),
  );
});

final projectBugsStreamProvider = StreamProvider.family<List<BugModel>, String>(
  (ref, projectId) {
    return ref.watch(bugRepositoryProvider).streamProjectBugs(projectId);
  },
);

final bugDetailsProvider = FutureProvider.family<BugModel?, String>((
  ref,
  bugId,
) {
  return ref.watch(bugRepositoryProvider).getBug(bugId);
});

final bugCommentsStreamProvider =
    StreamProvider.family<List<BugCommentModel>, String>((ref, bugId) {
      return ref.watch(bugRepositoryProvider).streamComments(bugId);
    });

final bugActivitiesStreamProvider =
    StreamProvider.family<List<BugActivityModel>, String>((ref, bugId) {
      return ref.watch(bugRepositoryProvider).streamActivities(bugId);
    });
