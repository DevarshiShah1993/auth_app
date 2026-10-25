import 'dart:async';

import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auth_app/features/auth/data/models/auth_event_type.dart';
import 'package:auth_app/features/auth/data/models/auth_state_event_model.dart';
import 'package:auth_app/features/auth/data/repositories/auth_failure_mapper.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Default [AuthRepository]. Converts exceptions to [Failure]s and applies
/// the OQ-01 session policy (see [AuthRepository]).
///
/// OQ-01 mechanism: a `signedIn` event that was not caused by
/// [signInWithPassword] (for example the session created by tapping the
/// confirmation link) is signed out locally, shown as `null` on
/// [authStateChanges] and reported as `Right(unit)` on [emailLinkResults].
/// Error events from the auth stream (invalid/expired link) become `Left` on
/// [emailLinkResults].
class AuthRepositoryImpl implements AuthRepository {
  /// Creates the repository.
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  /// True while a password sign-in is running; consumed by its `signedIn`.
  bool _expectingPasswordSignIn = false;

  late final Stream<_Processed> _processed = _dataSource.authStateChanges
      .asyncMap(_process)
      .where((p) => p != null)
      .cast<_Processed>()
      .asBroadcastStream();

  Future<_Processed?> _process(AuthStateEventModel event) async {
    switch (event.type) {
      case AuthEventType.error:
        return _Processed.link(
          left(AuthFailureMapper.fromException(event.error ?? Object())),
        );
      case AuthEventType.signedIn:
        if (_expectingPasswordSignIn) {
          _expectingPasswordSignIn = false;
          return _Processed.user(event.user);
        }
        // Session from the confirmation link: not a sign-in (OQ-01).
        try {
          await _dataSource.signOut();
        } on Object {
          // Local session is cleared before any network call; ignore.
        }
        return _Processed.linkAndSignedOut(right(unit));
      case AuthEventType.initialSession:
      case AuthEventType.signedOut:
      case AuthEventType.tokenRefreshed:
      case AuthEventType.userUpdated:
        return _Processed.user(event.user);
      case AuthEventType.other:
        return null;
    }
  }

  @override
  AppUser? get currentUser => _dataSource.currentUser;

  @override
  Stream<AppUser?> get authStateChanges =>
      _processed.where((p) => p.emitsUser).map((p) => p.user);

  @override
  Stream<Either<Failure, Unit>> get emailLinkResults => _processed
      .where((p) => p.linkResult != null)
      .map((p) => p.linkResult)
      .cast<Either<Failure, Unit>>();

  String _clean(String email) => email.trim().toLowerCase();

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } on Object catch (error) {
      return left(AuthFailureMapper.fromException(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> signUp({
    required String email,
    required String password,
  }) => _guard(() async {
    await _dataSource.signUp(email: _clean(email), password: password);
    return unit;
  });

  @override
  Future<Either<Failure, AppUser>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _expectingPasswordSignIn = true;
    final result = await _guard<AppUser>(
      () => _dataSource.signInWithPassword(
        email: _clean(email),
        password: password,
      ),
    );
    if (result.isLeft()) {
      _expectingPasswordSignIn = false;
    }
    return result;
  }

  @override
  Future<Either<Failure, Unit>> resendConfirmation({required String email}) =>
      _guard(() async {
        await _dataSource.resendConfirmation(email: _clean(email));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> signOut() => _guard(() async {
    await _dataSource.signOut();
    return unit;
  });
}

/// Result of processing one raw event.
class _Processed {
  const _Processed._({required this.emitsUser, this.user, this.linkResult});

  factory _Processed.user(AppUser? user) =>
      _Processed._(emitsUser: true, user: user);

  factory _Processed.link(Either<Failure, Unit> result) =>
      _Processed._(emitsUser: false, linkResult: result);

  factory _Processed.linkAndSignedOut(Either<Failure, Unit> result) =>
      _Processed._(emitsUser: true, linkResult: result);

  final bool emitsUser;
  final AppUser? user;
  final Either<Failure, Unit>? linkResult;
}
