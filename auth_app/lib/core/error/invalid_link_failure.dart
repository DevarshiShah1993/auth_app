import 'package:auth_app/core/error/auth_failure.dart';

/// The confirmation link is invalid or expired (`otp_expired`, `access_denied`).
class InvalidLinkFailure extends AuthFailure {
  /// Creates the failure. The message is for developers, not for display.
  const InvalidLinkFailure() : super('Invalid or expired link');
}
