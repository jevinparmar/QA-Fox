import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/firebase_providers.dart';
import '../../shared/providers/storage_providers.dart';

import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/bug_management/presentation/screens/bug_board_screen.dart';
import '../../features/bug_management/presentation/screens/bug_details_screen.dart';
import '../../features/bug_reporting/presentation/screens/multi_bug_composer_screen.dart';
import '../../features/dashboard/presentation/screens/chat_screen.dart';
import '../../features/dashboard/presentation/screens/chats_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/organizations/presentation/screens/create_organization_screen.dart';
import '../../features/organizations/presentation/screens/organization_details_screen.dart';
import '../../features/organizations/presentation/screens/organization_list_screen.dart';
import '../../features/profile/presentation/screens/connection_requests_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/user_search_screen.dart';
import '../../features/projects/presentation/screens/create_project_screen.dart';
import '../../features/projects/presentation/screens/project_details_screen.dart';
import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';
import 'route_paths.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Page<dynamic> _buildFadeSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final refreshStream = GoRouterRefreshStream(authService.authStateChanges);
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final user = authService.currentUser;
      final session = ref.read(sessionServiceProvider);
      final isAuthenticated = user != null || session.isLoggedIn;
      return RouteGuards.authRedirect(context, state, isAuthenticated);
    },
    routes: [
      // Splash
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // Stateful Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Chats
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.chats,
                name: RouteNames.chats,
                builder: (context, state) => const ChatsDashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.search,
                name: RouteNames.search,
                builder: (context, state) => const UserSearchScreen(),
              ),
            ],
          ),
          // Branch 2: Projects
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.projects,
                name: RouteNames.projects,
                builder: (context, state) => const ProjectListScreen(),
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Chat Detail & Multi-Bug Composer
      GoRoute(
        path: RoutePaths.chatDetails,
        name: RouteNames.chatDetails,
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return _buildFadeSlidePage(
            state: state,
            child: ChatScreen(chatId: chatId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.reportBug,
        name: RouteNames.reportBug,
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return _buildFadeSlidePage(
            state: state,
            child: MultiBugComposerScreen(chatId: chatId),
          );
        },
      ),

      // Bug Details & Bug Board
      GoRoute(
        path: RoutePaths.bugDetails,
        name: RouteNames.bugDetails,
        pageBuilder: (context, state) {
          final bugId = state.pathParameters['bugId']!;
          return _buildFadeSlidePage(
            state: state,
            child: BugDetailsScreen(bugId: bugId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.bugBoard,
        name: RouteNames.bugBoard,
        pageBuilder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return _buildFadeSlidePage(
            state: state,
            child: BugBoardScreen(projectId: projectId),
          );
        },
      ),

      // Connection Requests
      GoRoute(
        path: RoutePaths.connectionRequests,
        name: RouteNames.connectionRequests,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const ConnectionRequestsScreen(),
        ),
      ),

      // Projects Sub-routes
      GoRoute(
        path: RoutePaths.createProject,
        name: RouteNames.createProject,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const CreateProjectScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.projectDetails,
        name: RouteNames.projectDetails,
        pageBuilder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return _buildFadeSlidePage(
            state: state,
            child: ProjectDetailsScreen(projectId: projectId),
          );
        },
      ),

      // Organizations Sub-routes
      GoRoute(
        path: RoutePaths.organizations,
        name: RouteNames.organizations,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const OrganizationListScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.createOrganization,
        name: RouteNames.createOrganization,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const CreateOrganizationScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.organizationDetails,
        name: RouteNames.organizationDetails,
        pageBuilder: (context, state) {
          final orgId = state.pathParameters['organizationId']!;
          return _buildFadeSlidePage(
            state: state,
            child: OrganizationDetailsScreen(organizationId: orgId),
          );
        },
      ),

      // Profile & Settings
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const NotificationsScreen(),
        ),
      ),
    ],
  );
});
