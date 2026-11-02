import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_animated_item.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/project_model.dart';
import '../providers/project_provider.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(allUserProjectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Projects & Workspaces',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.business_outlined),
            tooltip: 'Organizations',
            onPressed: () => context.push(RoutePaths.organizations),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Project',
            onPressed: () => context.push(RoutePaths.createProject),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return AppEmptyView(
              icon: Icons.folder_open_outlined,
              title: 'No Projects Yet',
              message: 'Projects hold testing groups, bug reports, and team discussions.',
              buttonText: 'Create First Project',
              onButtonPressed: () => context.push(RoutePaths.createProject),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              return AppAnimatedItem(
                index: index,
                child: _buildProjectCard(context, ref, project, isDark),
              );
            },
          );
        },
        loading: () => const AppLoader(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'project_list_fab',
        onPressed: () => context.push(RoutePaths.createProject),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Project',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${project.name}"?\n\n'
          'This will permanently delete the project and its associated testing records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(64, 40),
            ),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(project.id);
        if (context.mounted) {
          context.showSuccessSnackBar('Project "${project.name}" deleted');
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar('Failed to delete project: $e', isError: true);
        }
      }
    }
  }

  Widget _buildProjectCard(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
    bool isDark,
  ) {
    IconData platformIcon = Icons.web;
    if (project.platform.toLowerCase().contains('android')) {
      platformIcon = Icons.android;
    } else if (project.platform.toLowerCase().contains('ios')) {
      platformIcon = Icons.apple;
    } else if (project.platform.toLowerCase().contains('multiple')) {
      platformIcon = Icons.devices;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(RoutePaths.projectDetailsPath(project.id)),
        onLongPress: () => _confirmDeleteProject(context, ref, project),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      platformIcon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Platform: ${project.platform} • ${project.memberIds.length} members',
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
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.secondary,
                    ),
                    tooltip: 'Open Project Group Chat',
                    onPressed: () {
                      context.push(
                        RoutePaths.chatDetailsPath(project.groupChatId),
                      );
                    },
                  ),
                ],
              ),
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bug_report,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${project.openBugCount} Open Bugs',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${project.totalBugCount} total reports',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.push(RoutePaths.bugBoardPath(project.id)),
                    icon: const Icon(Icons.view_kanban_outlined, size: 16),
                    label: const Text(
                      'Bug Board',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
