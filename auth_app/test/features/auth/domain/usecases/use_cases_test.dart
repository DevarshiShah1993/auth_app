import 'package:auth_app/core/error/invalid_credentials_failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:auth_app/features/auth/domain/usecases/observe_email_link_results.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_params.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:auth_app/features/auth/domain/usecases/params/no_params.dart';
import 'package:auth_app/features/auth/domain/usecases/resend_confirmation.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_out.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_up.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  const user = AppUser(id: '1', email: 'a@b.co', emailConfirmed: true);
  const creds = EmailPasswordParams(email: 'a@b.co', password: 'pass1234');

  setUp(() => repo = MockAuthRepository());

  group('SignUp', () {
    test('returns unit on success', () async {
      when(() => repo.signUp(email: 'a@b.co', password: 'pass1234'))
          .thenAnswer((_) async => right(unit));
      expect(await SignUp(repo)(creds), right<Object, Unit>(unit));
    });
    test('returns failure', () async {
      when(() => repo.signUp(email: 'a@b.co', password: 'pass1234'))
          .thenAnswer((_) async => left(const NetworkFailure('x')));
      expect(
        await SignUp(repo)(creds),
        left<NetworkFailure, Unit>(const NetworkFailure('x')),
      );
    });
  });

  group('SignInWithPassword', () {
    test('returns user on success', () async {
      when(() => repo.signInWithPassword(email: 'a@b.co', password: 'pass1234'))
          .thenAnswer((_) async => right(user));
      expect(
        await SignInWithPassword(repo)(creds),
        right<Object, AppUser>(user),
      );
    });
    test('returns failure', () async {
      when(() => repo.signInWithPassword(email: 'a@b.co', password: 'pass1234'))
          .thenAnswer((_) async => left(const InvalidCredentialsFailure()));
      final result = await SignInWithPassword(repo)(creds);
      expect(result.getLeft().toNullable(), const InvalidCredentialsFailure());
    });
  });

  group('ResendConfirmation', () {
    const params = EmailParams(email: 'a@b.co');
    test('returns unit on success', () async {
      when(() => repo.resendConfirmation(email: 'a@b.co'))
          .thenAnswer((_) async => right(unit));
      expect((await ResendConfirmation(repo)(params)).isRight(), isTrue);
    });
    test('returns failure', () async {
      when(() => repo.resendConfirmation(email: 'a@b.co'))
          .thenAnswer((_) async => left(const NetworkFailure('x')));
      expect((await ResendConfirmation(repo)(params)).isLeft(), isTrue);
    });
  });

  group('SignOut', () {
    test('returns unit on success', () async {
      when(() => repo.signOut()).thenAnswer((_) async => right(unit));
      expect((await SignOut(repo)(const NoParams())).isRight(), isTrue);
    });
    test('returns failure', () async {
      when(() => repo.signOut())
          .thenAnswer((_) async => left(const NetworkFailure('x')));
      expect((await SignOut(repo)(const NoParams())).isLeft(), isTrue);
    });
  });

  group('GetCurrentUser', () {
    test('returns the user', () async {
      when(() => repo.currentUser).thenReturn(user);
      expect(
        await GetCurrentUser(repo)(const NoParams()),
        right<Object, AppUser?>(user),
      );
    });
    test('returns null when signed out', () async {
      when(() => repo.currentUser).thenReturn(null);
      expect(
        (await GetCurrentUser(repo)(const NoParams())).toNullable(),
        isNull,
      );
    });
  });

  test('ObserveAuthState forwards the repository stream', () {
    when(() => repo.authStateChanges).thenAnswer((_) => Stream.value(user));
    expect(ObserveAuthState(repo)(const NoParams()), emits(user));
  });

  test('ObserveEmailLinkResults forwards the repository stream', () {
    when(() => repo.emailLinkResults)
        .thenAnswer((_) => Stream.value(right(unit)));
    expect(
      ObserveEmailLinkResults(repo)(const NoParams()),
      emits(right<Object, Unit>(unit)),
    );
  });
}
