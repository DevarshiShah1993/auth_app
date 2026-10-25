import 'package:auth_app/core/error/auth_failure.dart';

/// Wrong email or password (`invalid_credentials`).
class InvalidCredentialsFailure extends AuthFailure {
  /// Creates the failure. The message is for developers, not for display.
  const InvalidCredentialsFailure() : super('Invalid login credentials');
}
