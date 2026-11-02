import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/features/profile/presentation/screens/user_search_screen.dart';
import 'package:qafox/features/profile/presentation/providers/connection_provider.dart';
import 'package:qafox/features/projects/presentation/providers/project_provider.dart';
import 'package:qafox/features/projects/presentation/screens/project_details_screen.dart';
import 'package:qafox/features/projects/presentation/screens/project_list_screen.dart';
import 'package:qafox/shared/models/project_model.dart';
import 'package:qafox/shared/models/user_model.dart';
import 'package:qafox/shared/providers/firebase_providers.dart';

void main() {
  testWidgets('UserSearchScreen renders without throwing', (tester) async {
    final mockUser = UserModel(
      id: 'test_u1',
      fullName: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserModelStreamProvider.overrideWith(
            (ref) => Stream.value(mockUser),
          ),
          receivedRequestsStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          sentRequestsStreamProvider.overrideWith((ref) => Stream.value([])),
          connectedUsersStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: UserSearchScreen()),
      ),
    );

    await tester.pump();
    expect(find.byType(UserSearchScreen), findsOneWidget);
  });

  testWidgets('ProjectDetailsScreen renders without throwing', (tester) async {
    final mockUser = UserModel(
      id: 'test_u1',
      fullName: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );

    final mockProject = ProjectModel(
      id: 'dummy_project',
      organizationId: 'org_1',
      name: 'destination alert',
      description: 'Alerts destination arrivals',
      platform: 'Android',
      groupChatId: 'chat_1',
      memberIds: ['test_u1'],
      creatorId: 'test_u1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserModelStreamProvider.overrideWith(
            (ref) => Stream.value(mockUser),
          ),
          projectStreamProvider('dummy_project')
              .overrideWith((ref) => Stream.value(mockProject)),
          projectMembersProvider('dummy_project')
              .overrideWith((ref) => Future.value([mockUser])),
        ],
        child: const MaterialApp(
          home: ProjectDetailsScreen(projectId: 'dummy_project'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    expect(find.text('destination alert'), findsWidgets);
    expect(find.text('Group Master'), findsOneWidget);
  });

  testWidgets(
    'ProjectDetailsScreen with AppTheme.lightTheme and isMaster button renders without BoxConstraints infinite width exception',
    (tester) async {
      final mockUser = UserModel(
        id: 'master_u1',
        fullName: 'Master User',
        username: 'master',
        email: 'master@example.com',
        createdAt: DateTime.now(),
      );

      final mockProject = ProjectModel(
        id: 'dummy_project_2',
        organizationId: 'org_1',
        name: 'QA Fox Testing App',
        description: 'Comprehensive QA tracking system',
        platform: 'Web',
        groupChatId: 'chat_2',
        memberIds: ['master_u1'],
        creatorId: 'master_u1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserModelStreamProvider.overrideWith(
              (ref) => Stream.value(mockUser),
            ),
            projectStreamProvider('dummy_project_2')
                .overrideWith((ref) => Stream.value(mockProject)),
            projectMembersProvider('dummy_project_2')
                .overrideWith((ref) => Future.value([mockUser])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
              ),
            ),
            home: const ProjectDetailsScreen(projectId: 'dummy_project_2'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
      expect(find.text('+ Add Members'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ElevatedButton inside an unconstrained Row renders without throwing BoxConstraints forces infinite width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Row(
                children: [
                  const Text('Sample Label'),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Action Button'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Action Button'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProjectListScreen long-press on project card prompts Delete Project dialog',
    (tester) async {
      final mockProject = ProjectModel(
        id: 'proj_to_delete',
        organizationId: 'org_1',
        name: 'destination alert',
        description: 'location base alarm system',
        platform: 'Android',
        groupChatId: 'chat_del',
        memberIds: ['user_1'],
        creatorId: 'user_1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allUserProjectsStreamProvider.overrideWith(
              (ref) => Stream.value([mockProject]),
            ),
          ],
          child: const MaterialApp(home: ProjectListScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('destination alert'), findsOneWidget);

      // Long press the project card
      await tester.longPress(find.text('destination alert'));
      await tester.pumpAndSettle();

      // Verify Delete Project dialog appears
      expect(find.text('Delete Project?'), findsOneWidget);
      expect(
        find.textContaining(
          'Are you sure you want to delete "destination alert"?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Project?'), findsNothing);
    },
  );
}
