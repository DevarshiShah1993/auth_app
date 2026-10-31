import 'package:auth_app/core/error/auth_failure.dart';

/// The email address has not been confirmed yet (`email_not_confirmed`).
class EmailNotConfirmedFailure extends AuthFailure {
  /// Creates the failure. The message is for developers, not for display.
  const EmailNotConfirmedFailure() : super('Email not confirmed');
}
