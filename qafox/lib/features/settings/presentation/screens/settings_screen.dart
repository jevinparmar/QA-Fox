import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Account Section
          _buildSectionHeader('Account', isDark),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.push(RoutePaths.editProfile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.lock_reset,
                    color: AppColors.primary,
                  ),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.push(RoutePaths.forgotPassword),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Appearance Section
          _buildSectionHeader('Appearance', isDark),
          RadioGroup<ThemeMode>(
            groupValue: currentThemeMode,
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(val);
              }
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('Light Mode'),
                    value: ThemeMode.light,
                    activeColor: AppColors.primary,
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark Mode'),
                    value: ThemeMode.dark,
                    activeColor: AppColors.secondary,
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    title: Text('System Default'),
                    value: ThemeMode.system,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // About & General
          _buildSectionHeader('About QA Fox', isDark),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.accent,
                  ),
                  title: const Text('About QA Fox'),
                  subtitle: const Text(
                    'Version ${AppConstants.appVersion} • ${AppConstants.appTagline}',
                  ),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: AppConstants.appVersion,
                      applicationIcon: Image.asset(
                        AssetConstants.logoPath,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      applicationLegalese:
                          '© 2026 QA Fox Inc. All rights reserved.',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    final confirm = await AppDialog.show(
                      context,
                      title: 'Delete Account',
                      message: 'Are you sure? This will remove all your testing profile data and cannot be undone.',
                      confirmText: 'Delete',
                      isDestructive: true,
                    );
                    if (confirm == true) {
                      await ref.read(authControllerProvider.notifier).signOut();
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
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
