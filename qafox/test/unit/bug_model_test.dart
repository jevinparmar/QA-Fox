import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/core/enums/bug_category.dart';
import 'package:qafox/core/enums/bug_priority.dart';
import 'package:qafox/core/enums/bug_severity.dart';
import 'package:qafox/core/enums/bug_status.dart';
import 'package:qafox/shared/models/bug_model.dart';

void main() {
  group('BugModel Tests', () {
    test('serialization and deserialization maintains data integrity', () {
      final bug = BugModel(
        id: 'bug_123',
        bugNumber: 'BUG-001',
        projectId: 'proj_abc',
        organizationId: 'org_xyz',
        groupChatId: 'chat_123',
        reporterId: 'user_1',
        reporterName: 'Alice',
        title: 'Login Button Overflow',
        description: 'Text overflows on narrow screens.',
        category: BugCategory.uiUx,
        severity: BugSeverity.high,
        priority: BugPriority.urgent,
        status: BugStatus.open,
        createdAt: DateTime(2026, 11, 2, 10, 0),
      );

      final map = bug.toMap();
      expect(map['bugNumber'], 'BUG-001');
      expect(map['category'], 'uiUx');
      expect(map['severity'], 'high');
      expect(map['status'], 'open');

      final reconstructed = BugModel.fromMap(map, bug.id);
      expect(reconstructed.id, 'bug_123');
      expect(reconstructed.bugNumber, 'BUG-001');
      expect(reconstructed.title, 'Login Button Overflow');
      expect(reconstructed.category, BugCategory.uiUx);
      expect(reconstructed.severity, BugSeverity.high);
      expect(reconstructed.priority, BugPriority.urgent);
      expect(reconstructed.status, BugStatus.open);
    });

    test('BugStatus transitions and helpers work properly', () {
      expect(BugStatus.open.isOpen, isTrue);
      expect(BugStatus.inProgress.isOpen, isTrue);
      expect(BugStatus.fixed.isResolved, isTrue);
      expect(BugStatus.verified.isResolved, isTrue);
      expect(BugStatus.closed.isResolved, isTrue);
    });
  });
}
