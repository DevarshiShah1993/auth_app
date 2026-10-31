import 'package:auth_app/core/error/failure.dart';

/// A failure reported by the auth backend (invalid credentials, etc.).
class AuthFailure extends Failure {
  /// Creates an auth failure.
  const AuthFailure(super.message);
}
