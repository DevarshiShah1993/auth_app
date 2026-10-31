import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/rate_limit_failure.dart';
import 'package:auth_app/core/error/signup_disabled_failure.dart';
import 'package:auth_app/core/error/unknown_failure.dart';
import 'package:auth_app/core/error/user_already_exists_failure.dart';
import 'package:auth_app/core/error/weak_password_failure.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_up.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSignUp extends Mock implements SignUp {}

void main() {
  late MockSignUp signUp;
  late ResendCooldownStore store;

  setUpAll(
    () => registerFallbackValue(
      const EmailPasswordParams(email: 'a', password: 'b'),
    ),
  );

  setUp(() {
    signUp = MockSignUp();
    store = ResendCooldownStore();
  });

  SignUpBloc build() => SignUpBloc(signUp: signUp, cooldownStore: store);

  blocTest<SignUpBloc, SignUpState>(
    'success normalises the email, starts the cooldown and emits success',
    build: build,
    setUp: () => when(() => signUp(any())).thenAnswer((_) async => right(unit)),
    act: (bloc) => bloc.add(
      const SignUpSubmitted(email: '  A@B.co ', password: 'secret123'),
    ),
    expect: () => [
      const SignUpState(status: SubmitStatus.loading),
      const SignUpState(status: SubmitStatus.success, email: 'a@b.co'),
    ],
    verify: (_) {
      verify(
        () => signUp(
          const EmailPasswordParams(email: 'a@b.co', password: 'secret123'),
        ),
      ).called(1);
      expect(store.remainingSeconds('a@b.co'), 60);
    },
  );

  final failures = <String, Failure>{
    'user already exists': const UserAlreadyExistsFailure(),
    'weak password': const WeakPasswordFailure(),
    'rate limit': const RateLimitFailure(),
    'network': const NetworkFailure('offline'),
    'signup disabled': const SignupDisabledFailure(),
    'unknown': const UnknownFailure('boom'),
  };
  failures.forEach((name, failure) {
    blocTest<SignUpBloc, SignUpState>(
      'failure: $name',
      build: build,
      setUp: () =>
          when(() => signUp(any())).thenAnswer((_) async => left(failure)),
      act: (bloc) => bloc.add(
        const SignUpSubmitted(email: 'a@b.co', password: 'secret123'),
      ),
      expect: () => [
        const SignUpState(status: SubmitStatus.loading),
        SignUpState(status: SubmitStatus.failure, failure: failure),
      ],
      verify: (_) => expect(store.remainingSeconds('a@b.co'), 0),
    );
  });

  blocTest<SignUpBloc, SignUpState>(
    'dismissing a failure returns to initial',
    build: build,
    seed: () => const SignUpState(
      status: SubmitStatus.failure,
      failure: RateLimitFailure(),
    ),
    act: (bloc) => bloc.add(const SignUpFailureDismissed()),
    expect: () => [const SignUpState()],
  );

  blocTest<SignUpBloc, SignUpState>(
    'dismiss without a failure does nothing',
    build: build,
    act: (bloc) => bloc.add(const SignUpFailureDismissed()),
    expect: () => <SignUpState>[],
  );

  blocTest<SignUpBloc, SignUpState>(
    'ignores a submit while loading',
    build: build,
    seed: () => const SignUpState(status: SubmitStatus.loading),
    act: (bloc) =>
        bloc.add(const SignUpSubmitted(email: 'a@b.co', password: 'secret123')),
    expect: () => <SignUpState>[],
    verify: (_) => verifyNever(() => signUp(any())),
  );
}
