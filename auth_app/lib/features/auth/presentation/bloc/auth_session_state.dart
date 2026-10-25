import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_status.dart';
import 'package:auth_app/features/auth/presentation/bloc/email_link_result.dart';
import 'package:equatable/equatable.dart';

/// Immutable state of the app-wide session.
///
/// Routing reads it as follows: [status] `initial` shows the splash;
/// otherwise a non-null [user] means signed in. [linkResult] is a one-shot
/// value: it stays set until `AuthSessionLinkResultConsumed` is added.
class AuthSessionState extends Equatable {
  /// Creates a state.
  const AuthSessionState({
    this.status = AuthSessionStatus.initial,
    this.user,
    this.failure,
    this.linkResult,
  });

  /// Where the session is in its lifecycle.
  final AuthSessionStatus status;

  /// The signed-in user, or null.
  final AppUser? user;

  /// Why resolving the session failed (status `failure` only).
  final Failure? failure;

  /// Pending outcome of an opened confirmation link, or null.
  final EmailLinkResult? linkResult;

  /// Whether the initial session resolution is still running.
  bool get isResolving => status == AuthSessionStatus.initial;

  /// Whether a user is signed in (a logout in progress still counts).
  bool get isAuthenticated => !isResolving && user != null;

  @override
  List<Object?> get props => [status, user, failure, linkResult];
}
