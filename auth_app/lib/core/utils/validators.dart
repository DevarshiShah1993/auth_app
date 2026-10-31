import 'package:auth_app/core/utils/validation_messages.dart';

/// Pure form validators. Each returns an error message, or `null` when valid.
abstract final class Validators {
  /// Minimum length of a new password.
  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _letter = RegExp('[A-Za-z]');
  static final RegExp _digit = RegExp('[0-9]');

  /// Trims and lower-cases an email for sending and comparison.
  static String normalizeEmail(String value) => value.trim().toLowerCase();

  /// Required, trimmed, `local@domain.tld` format.
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || !_email.hasMatch(trimmed)) {
      return ValidationMessages.invalidEmail;
    }
    return null;
  }

  /// Sign-in password: required only, so legacy passwords are never blocked.
  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationMessages.passwordRequired;
    }
    return null;
  }

  /// Sign-up password: min 8 characters, at least one letter and one number.
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.length < minPasswordLength ||
        !_letter.hasMatch(password) ||
        !_digit.hasMatch(password)) {
      return ValidationMessages.weakPassword;
    }
    return null;
  }

  /// Confirm password must equal [password].
  static String? confirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty || confirm != password) {
      return ValidationMessages.passwordMismatch;
    }
    return null;
  }
}
