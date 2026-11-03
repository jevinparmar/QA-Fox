import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../providers/project_provider.dart';
import '../widgets/add_group_members_dialog.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final projectAsync = ref.watch(projectStreamProvider(projectId));
    final currentUser = ref.watch(currentUserModelStreamProvider).value;

    return projectAsync.when(
      loading: () => const Scaffold(body: Center(child: AppLoader())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: Center(child: Text('Error loading project: $err')),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project Details')),
            body: const Center(child: Text('Project not found.')),
          );
        }

        final isMaster =
            currentUser != null && project.isMaster(currentUser.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Open Group Chat',
                onPressed: () {
                  if (project.groupChatId.isNotEmpty) {
                    context.push(
                      RoutePaths.chatDetailsPath(project.groupChatId),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.view_kanban_outlined),
                tooltip: 'Bug Board',
                onPressed: () =>
                    context.push(RoutePaths.bugBoardPath(project.id)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Platform & Stats Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.secondary : AppColors.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.folder,
                          color: isDark ? AppColors.secondary : AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Platform: ${project.platform}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (project.projectUrl != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                project.projectUrl!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  project.description?.isNotEmpty == true
                      ? project.description!
                      : 'No detailed overview provided for this project.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Cards
                Row(
                  children: [
                    // Open Group Chat
                    Expanded(
                      child: _buildActionTile(
                        context: context,
                        icon: Icons.chat,
                        title: 'Group Chat',
                        subtitle: 'Testing channel',
                        color: isDark ? AppColors.secondary : AppColors.primary,
                        onTap: () => context.push(
                          RoutePaths.chatDetailsPath(project.groupChatId),
                        ),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Open Bug Board
                    Expanded(
                      child: _buildActionTile(
                        context: context,
                        icon: Icons.view_kanban,
                        title: 'Bug Board',
                        subtitle: '${project.openBugCount} open bugs',
                        color: AppColors.accent,
                        onTap: () =>
                            context.push(RoutePaths.bugBoardPath(project.id)),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Group Members & Master Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Group Members (${project.memberIds.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isMaster
                              ? 'You are the Group Master'
                              : 'Managed by Group Master',
                          style: TextStyle(
                            fontSize: 12,
                            color: isMaster
                                ? AppColors.accent
                                : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                            fontWeight: isMaster
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMaster) const SizedBox(width: 8),
                  if (isMaster)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          AddGroupMembersDialog.show(
                            context,
                            projectId: project.id,
                            groupName: project.name,
                            existingMemberIds: project.memberIds,
                          );
                        },
                        icon: const Icon(
                          Icons.person_add,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '+ Add Members',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Members List with Real Profiles
                Consumer(
                  builder: (context, ref, _) {
                    final membersAsync = ref.watch(
                      projectMembersProvider(projectId),
                    );

                    return membersAsync.when(
                      data: (members) {
                        // Sort so Group Master is always at the top
                        final sorted = List.of(members)
                          ..sort((a, b) {
                            if (a.id == b.id) return 0;
                            final aMaster = project.isMaster(a.id);
                            final bMaster = project.isMaster(b.id);
                            if (aMaster && !bMaster) return -1;
                            if (!aMaster && bMaster) return 1;
                            return a.fullName.compareTo(b.fullName);
                          });

                        return Material(
                          color: isDark
                              ? AppColors.surfaceDark
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sorted.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              indent: 64,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                            itemBuilder: (context, idx) {
                              final member = sorted[idx];
                              final isThisMaster = project.isMaster(member.id);
                              final isCurrent = member.id == currentUser?.id;

                              return ListTile(
                                onTap: () {
                                  if (isCurrent) {
                                    context.push(RoutePaths.profile);
                                  } else {
                                    context.push(
                                      RoutePaths.userProfilePath(member.id),
                                      extra: member,
                                    );
                                  }
                                },
                                leading: AppAvatar(
                                  name: member.fullName,
                                  imageUrl: member.photoUrl,
                                  size: 42,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  isCurrent
                                      ? '@${member.username} • ${member.email}'
                                      : '@${member.username} • ${member.designation ?? 'Tester'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isThisMaster)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF08A),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFEAB308),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '👑',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Group Master',
                                              style: TextStyle(
                                                color: Color(0xFF854D0E),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (isDark
                                                      ? AppColors.secondary
                                                      : AppColors.primary)
                                                  .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Tester',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.secondary
                                                : AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (isMaster && !isThisMaster) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        tooltip: 'Remove from group',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dCtx) => AlertDialog(
                                              title: const Text(
                                                'Remove Member?',
                                              ),
                                              content: Text(
                                                'Are you sure you want to remove ${member.fullName} from "${project.name}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dCtx,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors.error,
                                                      ),
                                                  onPressed: () =>
                                                      Navigator.pop(dCtx, true),
                                                  child: const Text(
                                                    'Remove',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref
                                                .read(projectRepositoryProvider)
                                                .removeMemberFromProject(
                                                  project.id,
                                                  member.id,
                                                );
                                            if (context.mounted) {
                                              context.showSnackBar(
                                                'Removed ${member.fullName} from group',
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: AppLoader(),
                        ),
                      ),
                      error: (err, _) =>
                          Center(child: Text('Error loading members: $err')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
