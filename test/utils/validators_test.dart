import 'package:agy_flutter/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () {
      expect(Validators.email(''), 'Email is required.');
      expect(Validators.email(null), 'Email is required.');
      expect(Validators.email('   '), 'Email is required.');
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('foo@'), isNotNull);
      expect(Validators.email('foo@bar'), isNotNull);
      expect(Validators.email('@bar.com'), isNotNull);
    });

    test('accepts well-formed addresses', () {
      expect(Validators.email('demo@agy.dev'), isNull);
      expect(Validators.email('a.b+tag@sub.example.co'), isNull);
      expect(Validators.email('  trimmed@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty', () {
      expect(Validators.password(''), 'Password is required.');
      expect(Validators.password(null), 'Password is required.');
    });

    test('rejects short passwords', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });

    test('accepts 8+ characters', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('a-strong-one'), isNull);
    });
  });

  group('Validators.name', () {
    test('rejects empty and too short', () {
      expect(Validators.name(''), 'Name is required.');
      expect(Validators.name('A'), 'Name is too short.');
    });

    test('accepts valid names', () {
      expect(Validators.name('Jo'), isNull);
      expect(Validators.name('Amorn'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects empty', () {
      expect(Validators.confirmPassword('', 'secret123'), isNotNull);
    });

    test('rejects mismatch', () {
      expect(
        Validators.confirmPassword('secret123', 'different'),
        'Passwords do not match.',
      );
    });

    test('accepts match', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });
}
