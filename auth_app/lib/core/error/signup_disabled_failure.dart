import 'package:auth_app/core/error/auth_failure.dart';

/// Sign-ups are disabled on the server (`signup_disabled`).
class SignupDisabledFailure extends AuthFailure {
  /// Creates the failure. The message is for developers, not for display.
  const SignupDisabledFailure() : super('Signups disabled');
}
