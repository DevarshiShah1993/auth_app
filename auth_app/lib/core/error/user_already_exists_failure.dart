import 'package:auth_app/core/error/auth_failure.dart';

/// The email is already registered (`user_already_exists` / `email_exists`).
class UserAlreadyExistsFailure extends AuthFailure {
  /// Creates the failure. The message is for developers, not for display.
  const UserAlreadyExistsFailure() : super('User already exists');
}
