import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/shared/models/project_model.dart';

void main() {
  group('ProjectModel Tests', () {
    test('serialization and group chat link generation', () {
      final now = DateTime.now();
      final project = ProjectModel(
        id: 'proj_999',
        organizationId: 'org_123',
        name: 'FreightFlow',
        description: 'Logistics web application',
        platform: 'Website',
        groupChatId: 'chat_project_proj_999',
        memberIds: ['user_owner', 'user_qa_1'],
        totalBugCount: 5,
        openBugCount: 2,
        createdAt: now,
        updatedAt: now,
      );

      final map = project.toMap();
      expect(map['groupChatId'], 'chat_project_proj_999');
      expect(map['platform'], 'Website');
      expect(map['totalBugCount'], 5);
      expect(map['openBugCount'], 2);

      final deserialized = ProjectModel.fromMap(map, 'proj_999');
      expect(deserialized.id, 'proj_999');
      expect(deserialized.groupChatId, 'chat_project_proj_999');
      expect(deserialized.memberIds.length, 2);
    });
  });
}
