import 'dart:async';

import 'package:auth_app/core/utils/app_constants.dart';
import 'package:auth_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auth_app/features/auth/data/models/auth_event_type.dart';
import 'package:auth_app/features/auth/data/models/auth_state_event_model.dart';
import 'package:auth_app/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of [AuthRemoteDataSource]. The only place that
/// calls Supabase auth. Never logs passwords or tokens.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// Creates the data source.
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppConstants.authRedirectUrl,
    );
  }

  @override
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign-in returned no user');
    }
    return UserModel.fromSupabase(user);
  }

  @override
  Future<void> resendConfirmation({required String email}) async {
    await _auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: AppConstants.authRedirectUrl,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromSupabase(user);
  }

  @override
  Stream<AuthStateEventModel> get authStateChanges =>
      _auth.onAuthStateChange.transform(
        StreamTransformer<AuthState, AuthStateEventModel>.fromHandlers(
          handleData: (state, sink) {
            final user = state.session?.user;
            sink.add(
              AuthStateEventModel(
                type: _mapEvent(state.event),
                user: user == null ? null : UserModel.fromSupabase(user),
              ),
            );
          },
          handleError: (error, stackTrace, sink) =>
              sink.add(AuthStateEventModel.error(error)),
        ),
      );

  static AuthEventType _mapEvent(AuthChangeEvent event) => switch (event) {
    AuthChangeEvent.initialSession => AuthEventType.initialSession,
    AuthChangeEvent.signedIn => AuthEventType.signedIn,
    AuthChangeEvent.signedOut => AuthEventType.signedOut,
    AuthChangeEvent.tokenRefreshed => AuthEventType.tokenRefreshed,
    AuthChangeEvent.userUpdated => AuthEventType.userUpdated,
    _ => AuthEventType.other,
  };
}
