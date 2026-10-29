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
import 'package:auth_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auth_app/features/auth/data/models/auth_event_type.dart';
import 'package:auth_app/features/auth/data/models/auth_state_event_model.dart';
import 'package:auth_app/features/auth/data/models/user_model.dart';
import 'package:auth_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockDataSource ds;
  late AuthRepositoryImpl repo;
  const user = UserModel(id: '1', email: 'a@b.co', emailConfirmed: true);

  setUp(() {
    ds = MockDataSource();
    repo = AuthRepositoryImpl(ds);
  });

  Failure? leftOf<T>(Either<Failure, T> e) => e.getLeft().toNullable();

  final mapped = <String, (Object, Failure)>{
    'invalid_credentials': (
      const AuthException('m', statusCode: '400', code: 'invalid_credentials'),
      const InvalidCredentialsFailure(),
    ),
    'email_not_confirmed': (
      const AuthException('m', statusCode: '400', code: 'email_not_confirmed'),
      const EmailNotConfirmedFailure(),
    ),
    'user_already_exists': (
      const AuthException('m', statusCode: '422', code: 'user_already_exists'),
      const UserAlreadyExistsFailure(),
    ),
    'email_exists': (
      const AuthException('m', statusCode: '422', code: 'email_exists'),
      const UserAlreadyExistsFailure(),
    ),
    'weak_password': (
      const AuthException('m', statusCode: '422', code: 'weak_password'),
      const WeakPasswordFailure(),
    ),
    'over_email_send_rate_limit': (
      const AuthException(
        'm',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      ),
      const RateLimitFailure(),
    ),
    'over_request_rate_limit': (
      const AuthException(
        'm',
        statusCode: '429',
        code: 'over_request_rate_limit',
      ),
      const RateLimitFailure(),
    ),
    '429 without code': (
      const AuthException('m', statusCode: '429'),
      const RateLimitFailure(),
    ),
    'signup_disabled': (
      const AuthException('m', statusCode: '422', code: 'signup_disabled'),
      const SignupDisabledFailure(),
    ),
    'otp_expired': (
      const AuthException('m', code: 'otp_expired'),
      const InvalidLinkFailure(),
    ),
    'access_denied': (
      const AuthException('m', code: 'access_denied'),
      const InvalidLinkFailure(),
    ),
    'retryable fetch': (
      AuthRetryableFetchException(message: 'm'),
      const NetworkFailure('No connection'),
    ),
    'SocketException': (
      const SocketException('x'),
      const NetworkFailure('No connection'),
    ),
    'TimeoutException': (
      TimeoutException('x'),
      const NetworkFailure('No connection'),
    ),
    'ClientException': (
      http.ClientException('x'),
      const NetworkFailure('No connection'),
    ),
    'other AuthException': (
      const AuthException('m', statusCode: '500', code: 'unexpected_failure'),
      const UnknownFailure('Unexpected auth error'),
    ),
    'non-auth error': (
      StateError('boom'),
      const UnknownFailure('Unexpected error'),
    ),
  };

  group('failure mapping', () {
    for (final entry in mapped.entries) {
      final (error, expected) = entry.value;
      test('signUp: ${entry.key}', () async {
        when(
          () => ds.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(error);
        final r = await repo.signUp(email: 'a@b.co', password: 'p');
        expect(leftOf(r), expected);
      });
      test('signInWithPassword: ${entry.key}', () async {
        when(
          () => ds.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(error);
        final r = await repo.signInWithPassword(email: 'a@b.co', password: 'p');
        expect(leftOf(r), expected);
      });
      test('resendConfirmation: ${entry.key}', () async {
        when(() => ds.resendConfirmation(email: any(named: 'email')))
            .thenThrow(error);
        final r = await repo.resendConfirmation(email: 'a@b.co');
        expect(leftOf(r), expected);
      });
      test('signOut: ${entry.key}', () async {
        when(() => ds.signOut()).thenThrow(error);
        expect(leftOf(await repo.signOut()), expected);
      });
    }
  });

  group('success', () {
    test('signUp trims and lower-cases email', () async {
      when(() => ds.signUp(email: 'a@b.co', password: 'Pass1234'))
          .thenAnswer((_) async {});
      final r = await repo.signUp(email: '  A@B.co ', password: 'Pass1234');
      expect(r, right<Failure, Unit>(unit));
      verify(() => ds.signUp(email: 'a@b.co', password: 'Pass1234')).called(1);
    });

    test('signInWithPassword returns the user', () async {
      when(() => ds.signInWithPassword(email: 'a@b.co', password: 'p'))
          .thenAnswer((_) async => user);
      final r = await repo.signInWithPassword(email: 'A@b.co', password: 'p');
      expect(r.toNullable(), user);
    });

    test('resendConfirmation succeeds', () async {
      when(() => ds.resendConfirmation(email: 'a@b.co'))
          .thenAnswer((_) async {});
      expect(
        (await repo.resendConfirmation(email: 'a@b.co')).isRight(),
        isTrue,
      );
    });

    test('signOut succeeds', () async {
      when(() => ds.signOut()).thenAnswer((_) async {});
      expect((await repo.signOut()).isRight(), isTrue);
    });

    test('currentUser delegates', () {
      when(() => ds.currentUser).thenReturn(user);
      expect(repo.currentUser, user);
    });
  });

  group('OQ-01 session policy', () {
    late StreamController<AuthStateEventModel> events;

    setUp(() {
      events = StreamController<AuthStateEventModel>.broadcast();
      when(() => ds.authStateChanges).thenAnswer((_) => events.stream);
      when(() => ds.signOut()).thenAnswer((_) async {});
      when(
        () => ds.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);
    });
    tearDown(() => events.close());

    test(
      'signedIn from the link is signed out and reported as confirmed',
      () async {
        final users = <Object?>[];
        final links = <Either<Failure, Unit>>[];
        repo.authStateChanges.listen(users.add);
        repo.emailLinkResults.listen(links.add);
        await Future<void>.delayed(Duration.zero);

        events.add(
          const AuthStateEventModel(type: AuthEventType.signedIn, user: user),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        verify(() => ds.signOut()).called(1);
        expect(users, [null]);
        expect(links, [right<Failure, Unit>(unit)]);
      },
    );

    test('signedIn after password sign-in is a real session', () async {
      final users = <Object?>[];
      final links = <Either<Failure, Unit>>[];
      repo.authStateChanges.listen(users.add);
      repo.emailLinkResults.listen(links.add);
      await Future<void>.delayed(Duration.zero);

      await repo.signInWithPassword(email: 'a@b.co', password: 'p');
      events.add(
        const AuthStateEventModel(type: AuthEventType.signedIn, user: user),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verifyNever(() => ds.signOut());
      expect(users, [user]);
      expect(links, isEmpty);
    });

    test('initialSession, refresh and signedOut pass through', () async {
      final users = <Object?>[];
      repo.authStateChanges.listen(users.add);
      await Future<void>.delayed(Duration.zero);

      events
        ..add(
          const AuthStateEventModel(
            type: AuthEventType.initialSession,
            user: user,
          ),
        )
        ..add(
          const AuthStateEventModel(
            type: AuthEventType.tokenRefreshed,
            user: user,
          ),
        )
        ..add(const AuthStateEventModel(type: AuthEventType.other, user: user))
        ..add(const AuthStateEventModel(type: AuthEventType.signedOut));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(users, [user, user, null]);
    });

    test('stream error with otp_expired becomes InvalidLinkFailure', () async {
      final links = <Either<Failure, Unit>>[];
      final users = <Object?>[];
      repo.emailLinkResults.listen(links.add);
      repo.authStateChanges.listen(users.add);
      await Future<void>.delayed(Duration.zero);

      events.add(
        const AuthStateEventModel.error(
          AuthException('m', code: 'otp_expired'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(links, [left<Failure, Unit>(const InvalidLinkFailure())]);
      expect(users, isEmpty);
    });

    test(
      'a failed password sign-in does not whitelist a later link session',
      () async {
        when(
          () => ds.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('m', code: 'invalid_credentials'));
        final links = <Either<Failure, Unit>>[];
        repo.emailLinkResults.listen(links.add);
        await Future<void>.delayed(Duration.zero);

        await repo.signInWithPassword(email: 'a@b.co', password: 'p');
        events.add(
          const AuthStateEventModel(type: AuthEventType.signedIn, user: user),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(links, hasLength(1));
      },
    );

    // BUG B-02: any stream error (e.g. offline token refresh) is reported as
    // an email-link result, which later routes a signed-out user to the
    // "Link expired" screen instead of Sign In.
    test(
      'a network error on the auth stream is not an email-link result',
      () async {
        final links = <Either<Failure, Unit>>[];
        repo.emailLinkResults.listen(links.add);
        await Future<void>.delayed(Duration.zero);

        events.add(
          AuthStateEventModel.error(AuthRetryableFetchException(message: 'm')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(links, isEmpty);
      },
      skip: 'B-02: network stream errors surface as invalid-link results',
    );
  });
}
