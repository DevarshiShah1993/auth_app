import 'package:auth_app/core/utils/validation_messages.dart';
import 'package:auth_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts valid, trimmed addresses', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('  user.name+tag@example.com '), isNull);
    });

    for (final bad in [
      null,
      '',
      '   ',
      'abc',
      'a@b',
      '@b.co',
      'a@.co',
      'a b@c.de',
    ]) {
      test('rejects "$bad"', () {
        expect(Validators.email(bad), ValidationMessages.invalidEmail);
      });
    }

    test('normalizeEmail trims and lower-cases', () {
      expect(Validators.normalizeEmail('  Foo@Bar.COM '), 'foo@bar.com');
    });
  });

  group('Validators.requiredPassword', () {
    test('accepts any non-empty value', () {
      expect(Validators.requiredPassword('x'), isNull);
    });
    test('rejects null and empty', () {
      expect(
        Validators.requiredPassword(null),
        ValidationMessages.passwordRequired,
      );
      expect(
        Validators.requiredPassword(''),
        ValidationMessages.passwordRequired,
      );
    });
  });

  group('Validators.newPassword', () {
    test('accepts 8+ chars with letter and number', () {
      expect(Validators.newPassword('abcdefg1'), isNull);
      expect(Validators.newPassword('1234567a!'), isNull);
    });
    test('rejects too short', () {
      expect(Validators.newPassword('abc123'), ValidationMessages.weakPassword);
    });
    test('rejects no number', () {
      expect(
        Validators.newPassword('abcdefgh'),
        ValidationMessages.weakPassword,
      );
    });
    test('rejects no letter', () {
      expect(
        Validators.newPassword('12345678'),
        ValidationMessages.weakPassword,
      );
    });
    test('rejects null and empty', () {
      expect(Validators.newPassword(null), ValidationMessages.weakPassword);
      expect(Validators.newPassword(''), ValidationMessages.weakPassword);
    });
  });

  group('Validators.confirmPassword', () {
    test('accepts equal values', () {
      expect(Validators.confirmPassword('abcdefg1', 'abcdefg1'), isNull);
    });
    test('rejects different, empty and null', () {
      expect(
        Validators.confirmPassword('abcdefg1', 'abcdefg2'),
        ValidationMessages.passwordMismatch,
      );
      expect(
        Validators.confirmPassword('abcdefg1', ''),
        ValidationMessages.passwordMismatch,
      );
      expect(
        Validators.confirmPassword('abcdefg1', null),
        ValidationMessages.passwordMismatch,
      );
    });
  });
}
