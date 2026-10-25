import 'dart:async';

import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_email_link_results.dart';
import 'package:auth_app/features/auth/domain/usecases/params/no_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_out.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_status.dart';
import 'package:auth_app/features/auth/presentation/bloc/email_link_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:auth_app/features/auth/presentation/bloc/auth_session_event.dart';
export 'package:auth_app/features/auth/presentation/bloc/auth_session_state.dart';
export 'package:auth_app/features/auth/presentation/bloc/auth_session_status.dart';
export 'package:auth_app/features/auth/presentation/bloc/email_link_result.dart';

/// App-wide session: resolves the stored session on launch, follows auth
/// changes, handles logout and exposes the email-link outcome.
class AuthSessionBloc extends Bloc<AuthSessionEvent, AuthSessionState> {
  /// Creates the bloc. Add [AuthSessionStarted] to begin.
  AuthSessionBloc({
    required this._getCurrentUser,
    required this._observeAuthState,
    required this._observeEmailLinkResults,
    required this._signOut,
  }) : super(const AuthSessionState()) {
    on<AuthSessionStarted>(_onStarted);
    on<AuthSessionUserChanged>(_onUserChanged);
    on<AuthSessionLinkResultReceived>(_onLinkResultReceived);
    on<AuthSessionLinkResultConsumed>(_onLinkResultConsumed);
    on<AuthSessionLogoutRequested>(_onLogoutRequested);
  }

  final GetCurrentUser _getCurrentUser;
  final ObserveAuthState _observeAuthState;
  final ObserveEmailLinkResults _observeEmailLinkResults;
  final SignOut _signOut;

  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<Object?>? _linkSubscription;

  Future<void> _onStarted(
    AuthSessionStarted event,
    Emitter<AuthSessionState> emit,
  ) async {
    if (_authSubscription != null) return;
    // Order matters: the auth stream must be listened to before the link
    // stream because they share one upstream (see AuthRepository).
    _authSubscription = _observeAuthState(const NoParams())
        .listen((user) => add(AuthSessionUserChanged(user)));
    _linkSubscription = _observeEmailLinkResults(const NoParams()).listen(
      (result) => add(
        AuthSessionLinkResultReceived(
          result.isRight()
              ? EmailLinkResult.confirmed
              : EmailLinkResult.invalid,
        ),
      ),
    );

    final result = await _getCurrentUser(const NoParams());
    result.match(
      (failure) => emit(
        AuthSessionState(
          status: AuthSessionStatus.failure,
          failure: failure,
          linkResult: state.linkResult,
        ),
      ),
      (user) => emit(
        AuthSessionState(
          status: AuthSessionStatus.success,
          user: user,
          linkResult: state.linkResult,
        ),
      ),
    );
  }

  void _onUserChanged(
    AuthSessionUserChanged event,
    Emitter<AuthSessionState> emit,
  ) {
    final user = event.user;
    // Keep `loading` while a logout runs and the user is still reported.
    final status = state.status == AuthSessionStatus.loading && user != null
        ? AuthSessionStatus.loading
        : AuthSessionStatus.success;
    emit(
      AuthSessionState(
        status: status,
        user: user,
        linkResult: state.linkResult,
      ),
    );
  }

  void _onLinkResultReceived(
    AuthSessionLinkResultReceived event,
    Emitter<AuthSessionState> emit,
  ) {
    emit(
      AuthSessionState(
        status: state.status,
        user: state.user,
        failure: state.failure,
        linkResult: event.result,
      ),
    );
  }

  void _onLinkResultConsumed(
    AuthSessionLinkResultConsumed event,
    Emitter<AuthSessionState> emit,
  ) {
    if (state.linkResult == null) return;
    emit(
      AuthSessionState(
        status: state.status,
        user: state.user,
        failure: state.failure,
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthSessionLogoutRequested event,
    Emitter<AuthSessionState> emit,
  ) async {
    if (!state.isAuthenticated || state.status == AuthSessionStatus.loading) {
      return;
    }
    emit(
      AuthSessionState(
        status: AuthSessionStatus.loading,
        user: state.user,
        linkResult: state.linkResult,
      ),
    );
    // A failed sign-out (for example offline) still clears the local
    // session (AC-26), so the result is signed out either way.
    await _signOut(const NoParams());
    emit(
      AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: state.linkResult,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _linkSubscription?.cancel();
    return super.close();
  }
}
