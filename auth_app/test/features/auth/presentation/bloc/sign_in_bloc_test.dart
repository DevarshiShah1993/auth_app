import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/core/error/email_not_confirmed_failure.dart';
import 'package:auth_app/core/error/invalid_credentials_failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/rate_limit_failure.dart';
import 'package:auth_app/core/error/unknown_failure.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInWithPassword extends Mock implements SignInWithPassword {}

void main() {
  late MockSignInWithPassword signIn;

  setUpAll(
    () => registerFallbackValue(
      const EmailPasswordParams(email: 'a', password: 'b'),
    ),
  );

  setUp(() => signIn = MockSignInWithPassword());

  SignInBloc build() => SignInBloc(signIn: signIn);

  blocTest<SignInBloc, SignInState>(
    'success normalises the email and emits success',
    build: build,
    setUp: () => when(() => signIn(any())).thenAnswer(
      (_) async =>
          right(const AppUser(id: '1', email: 'a@b.co', emailConfirmed: true)),
    ),
    act: (bloc) => bloc.add(
      const SignInSubmitted(email: '  A@B.co ', password: 'secret123'),
    ),
    expect: () => const [
      SignInState(status: SubmitStatus.loading),
      SignInState(status: SubmitStatus.success),
    ],
    verify: (_) => verify(
      () => signIn(
        const EmailPasswordParams(email: 'a@b.co', password: 'secret123'),
      ),
    ).called(1),
  );

  final failures = <String, Failure>{
    'invalid credentials': const InvalidCredentialsFailure(),
    'email not confirmed': const EmailNotConfirmedFailure(),
    'rate limit': const RateLimitFailure(),
    'network': const NetworkFailure('offline'),
    'unknown': const UnknownFailure('boom'),
  };
  failures.forEach((name, failure) {
    blocTest<SignInBloc, SignInState>(
      'emits failure for $name',
      build: build,
      setUp: () =>
          when(() => signIn(any())).thenAnswer((_) async => left(failure)),
      act: (bloc) =>
          bloc.add(const SignInSubmitted(email: 'a@b.co', password: 'x')),
      expect: () => [
        const SignInState(status: SubmitStatus.loading),
        SignInState(status: SubmitStatus.failure, failure: failure),
      ],
    );
  });

  blocTest<SignInBloc, SignInState>(
    'dismissing a failure resets to initial',
    build: build,
    seed: () => const SignInState(
      status: SubmitStatus.failure,
      failure: InvalidCredentialsFailure(),
    ),
    act: (bloc) => bloc.add(const SignInFailureDismissed()),
    expect: () => const [SignInState()],
  );

  blocTest<SignInBloc, SignInState>(
    'dismiss is ignored when there is no failure',
    build: build,
    act: (bloc) => bloc.add(const SignInFailureDismissed()),
    expect: () => const <SignInState>[],
  );
}
