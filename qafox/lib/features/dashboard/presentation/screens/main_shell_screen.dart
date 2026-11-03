import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/providers/notification_providers.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    // 1. Initialize native local notification service
    final localNotifier = ref.read(localNotificationServiceProvider);
    await localNotifier.initialize(
      onNotificationTapped: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty && mounted) {
          context.push(payload);
        }
      },
    );

    // 2. Request initial permissions on app launch (notifications, photos, videos, camera)
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.requestInitialAppPermissions();

    // 3. Start real-time background notification watcher for chats & requests
    ref.read(notificationWatcherProvider).startListening();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          indicatorColor: activeColor.withValues(
            alpha: isDark ? 0.22 : 0.12,
          ),
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: activeColor),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_search_outlined),
              selectedIcon: Icon(Icons.person_search, color: activeColor),
              label: 'Search',
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder, color: activeColor),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: activeColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
