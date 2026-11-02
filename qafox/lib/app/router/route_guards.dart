import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_paths.dart';

class RouteGuards {
  const RouteGuards._();

  static String? authRedirect(
    BuildContext context,
    GoRouterState state,
    bool isAuthenticated,
  ) {
    final location = state.matchedLocation;
    final isAuthRoute =
        location == RoutePaths.login ||
        location == RoutePaths.register ||
        location == RoutePaths.forgotPassword ||
        location == RoutePaths.splash;

    if (!isAuthenticated && !isAuthRoute) {
      return RoutePaths.login;
    }

    if (isAuthenticated &&
        (location == RoutePaths.login || location == RoutePaths.register)) {
      return RoutePaths.chats;
    }

    return null;
  }
}
