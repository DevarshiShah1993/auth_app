import 'dart:async';

import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/core/error/invalid_link_failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/unknown_failure.dart';
import 'package:auth_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auth_app/features/auth/data/models/auth_event_type.dart';
import 'package:auth_app/features/auth/data/models/auth_state_event_model.dart';
import 'package:auth_app/features/auth/data/models/user_model.dart';
import 'package:auth_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_email_link_results.dart';
import 'package:auth_app/features/auth/domain/usecases/params/no_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_out.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockObserveAuthState extends Mock implements ObserveAuthState {}

class MockObserveEmailLinkResults extends Mock
    implements ObserveEmailLinkResults {}

class MockSignOut extends Mock implements SignOut {}

class MockDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  const user = AppUser(id: '1', email: 'a@b.co', emailConfirmed: true);
  late MockGetCurrentUser getCurrentUser;
  late MockObserveAuthState observeAuthState;
  late MockObserveEmailLinkResults observeLinks;
  late MockSignOut signOut;
  late StreamController<AppUser?> authController;
  late StreamController<Either<Failure, Unit>> linkController;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    observeAuthState = MockObserveAuthState();
    observeLinks = MockObserveEmailLinkResults();
    signOut = MockSignOut();
    authController = StreamController<AppUser?>.broadcast();
    linkController = StreamController<Either<Failure, Unit>>.broadcast();
    when(() => observeAuthState(any()))
        .thenAnswer((_) => authController.stream);
    when(() => observeLinks(any())).thenAnswer((_) => linkController.stream);
    when(() => getCurrentUser(any())).thenAnswer((_) async => right(null));
    when(() => signOut(any())).thenAnswer((_) async => right(unit));
  });

  tearDown(() async {
    await authController.close();
    await linkController.close();
  });

  AuthSessionBloc build() => AuthSessionBloc(
    getCurrentUser: getCurrentUser,
    observeAuthState: observeAuthState,
    observeEmailLinkResults: observeLinks,
    signOut: signOut,
  );

  test('initial state is resolving and not authenticated', () {
    final state = build().state;
    expect(state.isResolving, isTrue);
    expect(state.isAuthenticated, isFalse);
  });

  blocTest<AuthSessionBloc, AuthSessionState>(
    'initial authenticated',
    setUp: () =>
        when(() => getCurrentUser(any())).thenAnswer((_) async => right(user)),
    build: build,
    act: (bloc) => bloc.add(const AuthSessionStarted()),
    expect: () => [
      const AuthSessionState(status: AuthSessionStatus.success, user: user),
    ],
    verify: (bloc) => expect(bloc.state.isAuthenticated, isTrue),
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'initial unauthenticated',
    build: build,
    act: (bloc) => bloc.add(const AuthSessionStarted()),
    expect: () => [const AuthSessionState(status: AuthSessionStatus.success)],
    verify: (bloc) {
      expect(bloc.state.isResolving, isFalse);
      expect(bloc.state.isAuthenticated, isFalse);
    },
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'resolution failure is treated as signed out',
    setUp: () =>
        when(() => getCurrentUser(any()))
            .thenAnswer((_) async => left(const UnknownFailure('x'))),
    build: build,
    act: (bloc) => bloc.add(const AuthSessionStarted()),
    expect: () => [
      const AuthSessionState(
        status: AuthSessionStatus.failure,
        failure: UnknownFailure('x'),
      ),
    ],
    verify: (bloc) {
      expect(bloc.state.isResolving, isFalse);
      expect(bloc.state.isAuthenticated, isFalse);
    },
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'follows auth state changes from the stream',
    build: build,
    act: (bloc) async {
      bloc.add(const AuthSessionStarted());
      await Future<void>.delayed(Duration.zero);
      authController.add(user);
      await Future<void>.delayed(Duration.zero);
      authController.add(null);
    },
    expect: () => [
      const AuthSessionState(status: AuthSessionStatus.success),
      const AuthSessionState(status: AuthSessionStatus.success, user: user),
      const AuthSessionState(status: AuthSessionStatus.success),
    ],
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'logout success signs out',
    setUp: () =>
        when(() => getCurrentUser(any())).thenAnswer((_) async => right(user)),
    build: build,
    act: (bloc) async {
      bloc.add(const AuthSessionStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthSessionLogoutRequested());
    },
    skip: 1,
    expect: () => [
      const AuthSessionState(status: AuthSessionStatus.loading, user: user),
      const AuthSessionState(status: AuthSessionStatus.success),
    ],
    verify: (_) => verify(() => signOut(any())).called(1),
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'logout failure still ends signed out',
    setUp: () {
      when(() => getCurrentUser(any())).thenAnswer((_) async => right(user));
      when(() => signOut(any()))
          .thenAnswer((_) async => left(const NetworkFailure('x')));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const AuthSessionStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthSessionLogoutRequested());
    },
    skip: 1,
    expect: () => [
      const AuthSessionState(status: AuthSessionStatus.loading, user: user),
      const AuthSessionState(status: AuthSessionStatus.success),
    ],
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'logout while signed out does nothing',
    build: build,
    act: (bloc) async {
      bloc.add(const AuthSessionStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthSessionLogoutRequested());
    },
    skip: 1,
    expect: () => <AuthSessionState>[],
    verify: (_) => verifyNever(() => signOut(any())),
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'link confirmed is exposed, stays signed out, and can be consumed',
    build: build,
    act: (bloc) async {
      bloc.add(const AuthSessionStarted());
      await Future<void>.delayed(Duration.zero);
      linkController.add(right(unit));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthSessionLinkResultConsumed());
    },
    skip: 1,
    expect: () => [
      const AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: EmailLinkResult.confirmed,
      ),
      const AuthSessionState(status: AuthSessionStatus.success),
    ],
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'invalid link is exposed',
    build: build,
    act: (bloc) async {
      bloc.add(const AuthSessionStarted());
      await Future<void>.delayed(Duration.zero);
      linkController.add(left(const InvalidLinkFailure()));
    },
    skip: 1,
    expect: () => [
      const AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: EmailLinkResult.invalid,
      ),
    ],
  );

  test('subscribes to authStateChanges before emailLinkResults', () async {
    final calls = <String>[];
    when(() => observeAuthState(any())).thenAnswer((_) {
      calls.add('auth');
      return authController.stream;
    });
    when(() => observeLinks(any())).thenAnswer((_) {
      calls.add('link');
      return linkController.stream;
    });
    final bloc = build()..add(const AuthSessionStarted());
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['auth', 'link']);
    await bloc.close();
  });

  group('B-02 with the real repository', () {
    const user = UserModel(id: '1', email: 'a@b.co', emailConfirmed: true);
    late MockDataSource ds;
    late StreamController<AuthStateEventModel> events;
    late AuthSessionBloc bloc;

    setUp(() {
      ds = MockDataSource();
      events = StreamController<AuthStateEventModel>.broadcast();
      when(() => ds.authStateChanges).thenAnswer((_) => events.stream);
      when(() => ds.currentUser).thenReturn(user);
      when(() => ds.signOut()).thenAnswer((_) async {});
      final repo = AuthRepositoryImpl(ds);
      bloc = AuthSessionBloc(
        getCurrentUser: GetCurrentUser(repo),
        observeAuthState: ObserveAuthState(repo),
        observeEmailLinkResults: ObserveEmailLinkResults(repo),
        signOut: SignOut(repo),
      );
    });

    tearDown(() async {
      await bloc.close();
      await events.close();
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 10));

    test(
      'offline refresh failure then logout ends signed out, no link result',
      () async {
        bloc.add(const AuthSessionStarted());
        await settle();
        expect(bloc.state.isAuthenticated, isTrue);

        events.add(
          AuthStateEventModel.error(AuthRetryableFetchException(message: 'm')),
        );
        await settle();
        expect(bloc.state.linkResult, isNull);

        bloc.add(const AuthSessionLogoutRequested());
        events.add(const AuthStateEventModel(type: AuthEventType.signedOut));
        await settle();

        expect(bloc.state.isAuthenticated, isFalse);
        expect(bloc.state.linkResult, isNull);
      },
    );

    test(
      'an expired-link stream error still yields the invalid result',
      () async {
        bloc.add(const AuthSessionStarted());
        await settle();

        events.add(
          const AuthStateEventModel.error(
            AuthException('m', code: 'otp_expired'),
          ),
        );
        await settle();

        expect(bloc.state.linkResult, EmailLinkResult.invalid);
      },
    );
  });
}
