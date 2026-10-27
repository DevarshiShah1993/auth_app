import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/core/error/invalid_link_failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/rate_limit_failure.dart';
import 'package:auth_app/core/error/signup_disabled_failure.dart';
import 'package:auth_app/core/error/user_already_exists_failure.dart';
import 'package:auth_app/core/error/weak_password_failure.dart';

/// Maps a [Failure] to the final user-facing copy (requirements section 6).
/// Raw failure messages are never shown.
abstract final class FailureMessages {
  /// Shown when the email is already registered.
  static const String emailExists =
      'An account with this email already exists. Try signing in.';

  /// Shown when the server rejects the password.
  static const String weakPassword =
      'Password is too weak. Use at least 8 characters with a letter and a '
      'number.';

  /// Shown on HTTP 429 style errors.
  static const String rateLimit =
      'Too many attempts. Please wait a moment and try again.';

  /// Shown when the device is offline or the request timed out.
  static const String network =
      'No connection. Check your internet and try again.';

  /// Shown when sign-ups are disabled server side.
  static const String signupDisabled = 'Sign up is currently unavailable.';

  /// Shown for an expired or used confirmation link.
  static const String linkExpired = 'This link is invalid or has expired';

  /// Fallback for anything else.
  static const String generic = 'Something went wrong. Please try again.';

  /// Confirmation shown after a successful resend.
  static const String resendSuccess = 'Confirmation email sent';

  /// Returns the copy for [failure].
  static String of(Failure failure) => switch (failure) {
    UserAlreadyExistsFailure() => emailExists,
    WeakPasswordFailure() => weakPassword,
    RateLimitFailure() => rateLimit,
    NetworkFailure() => network,
    SignupDisabledFailure() => signupDisabled,
    InvalidLinkFailure() => linkExpired,
    _ => generic,
  };
}
