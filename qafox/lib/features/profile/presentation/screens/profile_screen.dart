import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/connection_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final currentUserAsync = ref.watch(currentUserModelStreamProvider);
    final connectionsAsync = ref.watch(connectedUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please log in to view profile.'));
          }

          final connCount = connectionsAsync.value?.length ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with online status
                AppAvatar(
                  name: user.fullName,
                  imageUrl: user.photoUrl,
                  size: 96,
                  isOnline: true,
                  showOnlineIndicator: true,
                ),
                const SizedBox(height: 14),

                // Name & Username
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username} • ${user.email}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (user.designation != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.designation!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Bio
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Connections Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => context.push(RoutePaths.search),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$connCount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Connections',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 330) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppButton(
                            text: 'Edit Profile',
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            variant: AppButtonVariant.outline,
                            height: 44,
                            onPressed: () =>
                                context.push(RoutePaths.editProfile),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            text: 'Organizations',
                            icon: const Icon(Icons.business_outlined, size: 16),
                            variant: AppButtonVariant.primary,
                            height: 44,
                            onPressed: () =>
                                context.push(RoutePaths.organizations),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Edit Profile',
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            variant: AppButtonVariant.outline,
                            height: 44,
                            onPressed: () =>
                                context.push(RoutePaths.editProfile),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'Organizations',
                            icon: const Icon(Icons.business_outlined, size: 16),
                            variant: AppButtonVariant.primary,
                            height: 44,
                            onPressed: () =>
                                context.push(RoutePaths.organizations),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Profile Menu Sections
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.people_outline,
                          color: AppColors.secondary,
                        ),
                        title: const Text('Connection Requests'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () =>
                            context.push(RoutePaths.connectionRequests),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.secondary,
                        ),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => context.push(RoutePaths.notifications),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.secondary,
                        ),
                        title: const Text('Settings & Preferences'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => context.push(RoutePaths.settings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: AppColors.error,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          final confirm = await AppDialog.show(
                            context,
                            title: 'Logout',
                            message:
                                'Are you sure you want to log out of QA Fox?',
                            confirmText: 'Logout',
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signOut();
                            if (context.mounted) {
                              context.go(RoutePaths.login);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoader(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
