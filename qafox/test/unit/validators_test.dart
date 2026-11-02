import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/core/utils/validators.dart';

void main() {
  group('Validators Test Suite', () {
    test('required validator enforces non-empty values', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('Valid text'), isNull);
    });

    test('email validator verifies standard and edge-case email formats', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.email('test@'), isNotNull);
      expect(Validators.email('@domain.com'), isNotNull);
      expect(Validators.email('user@domain'), isNotNull);
      expect(Validators.email('tester@qafox.com'), isNull);
      expect(Validators.email('qafox.dev@sub.domain.co'), isNull);
    });

    test('password validator enforces minimum length of 6 characters', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('SecureP@ssw0rd!'), isNull);
    });

    test('confirmPassword validator detects mismatches accurately', () {
      expect(Validators.confirmPassword(null, 'secret'), isNotNull);
      expect(Validators.confirmPassword('', 'secret'), isNotNull);
      expect(Validators.confirmPassword('secret1', 'secret2'), isNotNull);
      expect(Validators.confirmPassword('Secret', 'secret'), isNotNull);
      expect(Validators.confirmPassword('secret', 'secret'), isNull);
    });

    test('phone validator allows null/empty and validates phone patterns', () {
      expect(Validators.phone(null), isNull);
      expect(Validators.phone(''), isNull);
      expect(Validators.phone('   '), isNull);
      expect(Validators.phone('+15551234567'), isNull);
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('123'), isNotNull); // too short
      expect(Validators.phone('phone123'), isNotNull); // alpha chars
    });

    test('minLength validator verifies character thresholds', () {
      expect(Validators.minLength(null, 3), isNotNull);
      expect(Validators.minLength('ab', 3), isNotNull);
      expect(Validators.minLength('abc', 3), isNull);
      expect(Validators.minLength('abcd', 3), isNull);
    });
  });
}
