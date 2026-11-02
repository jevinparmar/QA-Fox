import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/shared/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('serialization and deserialization maintains all user attributes', () {
      final user = UserModel(
        id: 'user_tester_01',
        email: 'tester01@qafox.com',
        fullName: 'Jane Developer',
        username: 'janedev',
        phoneNumber: '+15550001111',
        designation: 'Senior QA Engineer',
        bio: 'Passionate about automated and manual testing',
        photoUrl: 'https://storage.googleapis.com/qafox/avatar.png',
        isOnline: true,
        lastSeen: DateTime(2026, 11, 2, 12, 0),
        createdAt: DateTime(2026, 11, 1, 9, 0),
      );

      final map = user.toMap();
      expect(map['email'], 'tester01@qafox.com');
      expect(map['fullName'], 'Jane Developer');
      expect(map['username'], 'janedev');
      expect(map['designation'], 'Senior QA Engineer');
      expect(map['isOnline'], true);

      final deserialized = UserModel.fromMap(map, user.id);
      expect(deserialized.id, 'user_tester_01');
      expect(deserialized.fullName, 'Jane Developer');
      expect(deserialized.username, 'janedev');
      expect(deserialized.phoneNumber, '+15550001111');
      expect(deserialized.designation, 'Senior QA Engineer');
      expect(deserialized.bio, 'Passionate about automated and manual testing');
      expect(deserialized.isOnline, true);
    });

    test('initials computation handles single and multi-word names', () {
      final user1 = UserModel(
        id: '1',
        email: 'test@qafox.com',
        fullName: 'Jane Doe',
        username: 'janedoe',
      );
      expect(user1.initials, 'JD');

      final user2 = UserModel(
        id: '2',
        email: 'test@qafox.com',
        fullName: 'Administrator',
        username: 'admin',
      );
      expect(user2.initials, 'A');

      final user3 = UserModel(
        id: '3',
        email: 'test@qafox.com',
        fullName: '',
        username: 'anon',
      );
      expect(user3.initials, '?');
    });

    test('copyWith updates specified fields only', () {
      final original = UserModel(
        id: 'u1',
        email: 'original@qafox.com',
        fullName: 'Original Name',
        username: 'orig',
        designation: 'Tester',
      );

      final updated = original.copyWith(
        fullName: 'Updated Name',
        designation: 'Lead QA',
      );

      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.fullName, 'Updated Name');
      expect(updated.designation, 'Lead QA');
    });
  });
}
