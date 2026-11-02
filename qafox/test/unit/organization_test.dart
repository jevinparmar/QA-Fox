import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/core/enums/user_role.dart';
import 'package:qafox/shared/models/organization_model.dart';

void main() {
  group('OrganizationModel Tests', () {
    test('serialization and member role parsing', () {
      final now = DateTime.now();
      final org = OrganizationModel(
        id: 'org_123',
        name: 'ABC Technologies',
        description: 'Software QA consultancy',
        ownerId: 'user_owner',
        memberCount: 3,
        createdAt: now,
        updatedAt: now,
      );

      final map = org.toMap();
      expect(map['name'], 'ABC Technologies');
      expect(map['ownerId'], 'user_owner');
      expect(map['memberCount'], 3);

      final deserialized = OrganizationModel.fromMap(map, 'org_123');
      expect(deserialized.id, 'org_123');
      expect(deserialized.name, org.name);
      expect(deserialized.ownerId, org.ownerId);
      expect(deserialized.memberCount, 3);
    });

    test('OrgMemberModel parsing logic', () {
      final member = OrgMemberModel(
        userId: 'user_tester',
        organizationId: 'org_123',
        role: UserRole.tester,
        email: 'tester@qafox.com',
        fullName: 'Sarah Tester',
      );

      final map = member.toMap();
      expect(map['role'], 'tester');
      expect(map['email'], 'tester@qafox.com');

      final deserialized = OrgMemberModel.fromMap(map, 'user_tester');
      expect(deserialized.role, UserRole.tester);
      expect(deserialized.email, 'tester@qafox.com');
    });

    test('UserRole parsing logic', () {
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('tester'), UserRole.tester);
      expect(UserRole.fromString('developer'), UserRole.developer);
      expect(
        UserRole.fromString('unknown'),
        UserRole.tester,
      ); // default fallback
    });
  });
}
