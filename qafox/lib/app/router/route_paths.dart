class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

  // Bottom Nav Tabs
  static const String chats = '/chats';
  static const String search = '/search';
  static const String projects = '/projects';
  static const String profile = '/profile';

  // Detail Paths
  static const String chatDetails = '/chat/:chatId';
  static const String reportBug = '/chat/:chatId/report-bug';
  static const String bugDetails = '/bug/:bugId';
  static const String bugBoard = '/project/:projectId/bugs';
  static const String connectionRequests = '/search/requests';
  static const String createProject = '/projects/create';
  static const String projectDetails = '/projects/:projectId';
  static const String organizations = '/organizations';
  static const String createOrganization = '/organizations/create';
  static const String organizationDetails = '/organizations/:organizationId';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  static String chatDetailsPath(String chatId) => '/chat/$chatId';
  static String reportBugPath(String chatId) => '/chat/$chatId/report-bug';
  static String bugDetailsPath(String bugId) => '/bug/$bugId';
  static String bugBoardPath(String projectId) => '/project/$projectId/bugs';
  static String projectDetailsPath(String projectId) => '/projects/$projectId';
  static String organizationDetailsPath(String orgId) =>
      '/organizations/$orgId';
}
