import 'package:auth_app/core/error/auth_failure.dart';

/// Too many requests (`over_*_rate_limit` or HTTP 429).
class RateLimitFailure extends AuthFailure {
  /// Creates the failure. The message is for developers, not for display.
  const RateLimitFailure() : super('Rate limit exceeded');
}
