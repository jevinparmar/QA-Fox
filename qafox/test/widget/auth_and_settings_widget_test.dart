import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:qafox/features/settings/presentation/screens/settings_screen.dart';
import 'package:qafox/shared/providers/notification_providers.dart';

void main() {
  group('Auth & Settings Screen Widget Tests', () {
    testWidgets('NotificationsScreen renders empty state gracefully', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userNotificationsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All Caught Up!'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders themes and options without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });
}
