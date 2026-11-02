import '../../../../shared/widgets/app_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/bug_status.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/bug_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../bug_reporting/presentation/providers/bug_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';

class BugDetailsScreen extends ConsumerStatefulWidget {
  final String bugId;

  const BugDetailsScreen({super.key, required this.bugId});

  @override
  ConsumerState<BugDetailsScreen> createState() => _BugDetailsScreenState();
}

class _BugDetailsScreenState extends ConsumerState<BugDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _changeStatus(BugModel bug, BugStatus newStatus) async {
    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    try {
      await ref
          .read(bugRepositoryProvider)
          .updateBugStatus(
            bugId: bug.id,
            newStatus: newStatus,
            actorId: user.id,
            actorName: user.fullName,
            actorAvatar: user.photoUrl,
          );
      if (mounted) {
        context.showSuccessSnackBar('Status updated to ${newStatus.label}');
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _showAssigneeModal(BugModel bug) async {
    final membersAsync = ref.read(orgMembersStreamProvider(bug.organizationId));
    final members = membersAsync.value ?? [];

    AppBottomSheet.show(
      context: context,
      title: 'Assign Developer / Teammate',
      child: members.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No team members found in this organization.'),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (itemCtx, index) {
                final member = members[index];
                return ListTile(
                  leading: AppAvatar(
                    name: member.fullName,
                    imageUrl: member.photoUrl,
                    size: 36,
                  ),
                  title: Text(
                    member.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(member.role.label),
                  onTap: () async {
                    Navigator.pop(context);
                    final currentUser = ref
                        .read(currentUserModelStreamProvider)
                        .value;
                    if (currentUser == null) return;

                    await ref
                        .read(bugRepositoryProvider)
                        .assignBug(
                          bugId: bug.id,
                          assigneeId: member.userId,
                          assigneeName: member.fullName,
                          assigneeAvatar: member.photoUrl,
                          actorId: currentUser.id,
                          actorName: currentUser.fullName,
                        );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bug assigned to ${member.fullName}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _postComment(BugModel bug) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    _commentController.clear();
    setState(() => _isPostingComment = true);

    try {
      await ref
          .read(bugRepositoryProvider)
          .addComment(
            bugId: bug.id,
            authorId: user.id,
            authorName: user.fullName,
            authorAvatar: user.photoUrl,
            content: text,
          );
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Real-time stream of this specific bug document
    final bugStream = ref
        .watch(firestoreServiceProvider)
        .streamDoc('${FirestoreConstants.bugs}/${widget.bugId}');

    return StreamBuilder(
      stream: bugStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: AppLoader()));
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            snapshot.data!.data() == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bug Details')),
            body: const Center(child: Text('Bug report not found.')),
          );
        }

        final bug = BugModel.fromMap(snapshot.data!.data()!, snapshot.data!.id);
        final commentsAsync = ref.watch(bugCommentsStreamProvider(bug.id));
        final activitiesAsync = ref.watch(bugActivitiesStreamProvider(bug.id));

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.foxGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bug.bugNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bug.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<BugStatus>(
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: 'Change Status',
                onSelected: (newStatus) => _changeStatus(bug, newStatus),
                itemBuilder: (context) => BugStatus.values.map((status) {
                  return PopupMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status & Badges Row
                Row(
                  children: [
                    AppBadge.status(bug.status),
                    const SizedBox(width: 8),
                    AppBadge.severity(bug.severity),
                    const SizedBox(width: 8),
                    AppBadge.priority(bug.priority),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bug.category.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  bug.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Reporter and Assignee Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            AppAvatar(
                              name: bug.reporterName,
                              imageUrl: bug.reporterAvatar,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reported by',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    bug.reporterName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showAssigneeModal(bug),
                          child: Row(
                            children: [
                              AppAvatar(
                                name: bug.assigneeName ?? 'Unassigned',
                                imageUrl: bug.assigneeAvatar,
                                size: 32,
                                backgroundColor: Colors.amber.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Assignee',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      bug.assigneeName ?? 'Tap to assign',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: bug.assigneeName != null
                                            ? null
                                            : AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  bug.description.isNotEmpty
                      ? bug.description
                      : 'No description provided.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // Attachments Gallery
                if (bug.attachmentUrls.isNotEmpty) ...[
                  Text(
                    'Attachments (${bug.attachmentUrls.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: bug.attachmentUrls.length,
                      itemBuilder: (context, index) {
                        final url = bug.attachmentUrls[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 140,
                              color: Colors.black12,
                              child: AppNetworkImage(
                                url: url,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (_, _, _) => const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Reproduction Details (if provided)
                if (bug.stepsToReproduce != null ||
                    bug.expectedResult != null ||
                    bug.actualResult != null) ...[
                  const Text(
                    'Reproduction & Behavior',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bug.screenName != null) ...[
                          Text(
                            'Screen: ${bug.screenName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (bug.stepsToReproduce != null) ...[
                          const Text(
                            'Steps to Reproduce:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            bug.stepsToReproduce!,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (bug.expectedResult != null) ...[
                          const Text(
                            'Expected Result:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            bug.expectedResult!,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (bug.actualResult != null) ...[
                          const Text(
                            'Actual Result:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            bug.actualResult!,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Comments & Discussions Section
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'Discussion & Comments',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 8),

                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'No comments yet. Start the conversation below.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppAvatar(
                                name: c.authorName,
                                imageUrl: c.authorAvatar,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            c.authorName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            c.createdAt?.chatTimestamp ?? '',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.content,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const AppLoader(size: 20),
                  error: (e, _) => Text('Error loading comments: $e'),
                ),

                const SizedBox(height: 12),

                // Comment input box
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment or test finding...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          isDense: true,
                          fillColor: isDark
                              ? AppColors.surfaceDark
                              : const Color(0xFFF1F5F9),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isPostingComment
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                        onPressed: _isPostingComment
                            ? null
                            : () => _postComment(bug),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Activity History Section
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Activity Timeline',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return const Text(
                        'No activity records.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${act.actorName} ${act.action}: ${act.toValue ?? ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              Text(
                                act.timestamp?.chatTimestamp ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
