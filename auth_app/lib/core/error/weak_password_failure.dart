import 'package:auth_app/core/error/auth_failure.dart';

/// The server rejected the password as too weak (`weak_password`).
class WeakPasswordFailure extends AuthFailure {
  /// Creates the failure. The message is for developers, not for display.
  const WeakPasswordFailure() : super('Weak password');
}
