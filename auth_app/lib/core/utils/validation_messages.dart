/// Client-side validation copy (final copy from the design doc).
abstract final class ValidationMessages {
  /// Shown for an empty or malformed email.
  static const String invalidEmail = 'Enter a valid email address';

  /// Shown when a new password breaks the strength rule.
  static const String weakPassword =
      'Password must be at least 8 characters and include a letter and a number';

  /// Shown when the confirm field differs from the password.
  static const String passwordMismatch = 'Passwords do not match';

  /// Shown when the sign-in password is empty.
  static const String passwordRequired = 'Enter your password';
}
