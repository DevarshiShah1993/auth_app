import 'dart:async';
import 'dart:io';

import 'package:auth_app/core/error/email_not_confirmed_failure.dart';
import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/core/error/invalid_credentials_failure.dart';
import 'package:auth_app/core/error/invalid_link_failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/rate_limit_failure.dart';
import 'package:auth_app/core/error/signup_disabled_failure.dart';
import 'package:auth_app/core/error/unknown_failure.dart';
import 'package:auth_app/core/error/user_already_exists_failure.dart';
import 'package:auth_app/core/error/weak_password_failure.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts backend and network exceptions to typed [Failure]s.
///
/// Matches by error code first (never by message text); HTTP 429 is the only
/// status-based fallback. Raw server messages are discarded so they cannot
/// leak to the UI or logs.
abstract final class AuthFailureMapper {
  /// Maps any thrown object.
  static Failure fromException(Object error) {
    if (error is AuthRetryableFetchException) {
      return const NetworkFailure('No connection');
    }
    if (error is AuthException) {
      return fromCode(error.code, statusCode: error.statusCode);
    }
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException) {
      return const NetworkFailure('No connection');
    }
    return const UnknownFailure('Unexpected error');
  }

  /// Maps a Supabase error [code] (and optional HTTP [statusCode]).
  static Failure fromCode(String? code, {String? statusCode}) {
    switch (code) {
      case 'invalid_credentials':
        return const InvalidCredentialsFailure();
      case 'email_not_confirmed':
        return const EmailNotConfirmedFailure();
      case 'user_already_exists':
      case 'email_exists':
        return const UserAlreadyExistsFailure();
      case 'weak_password':
        return const WeakPasswordFailure();
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return const RateLimitFailure();
      case 'signup_disabled':
        return const SignupDisabledFailure();
      case 'otp_expired':
      case 'access_denied':
        return const InvalidLinkFailure();
    }
    if (statusCode == '429') {
      return const RateLimitFailure();
    }
    return const UnknownFailure('Unexpected auth error');
  }
}
