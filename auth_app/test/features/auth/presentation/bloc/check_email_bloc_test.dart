import 'dart:async';

import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/rate_limit_failure.dart';
import 'package:auth_app/core/error/unknown_failure.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_params.dart';
import 'package:auth_app/features/auth/domain/usecases/resend_confirmation.dart';
import 'package:auth_app/features/auth/presentation/bloc/check_email_bloc.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockResendConfirmation extends Mock implements ResendConfirmation {}

void main() {
  late MockResendConfirmation resend;
  late DateTime now;
  late ResendCooldownStore store;
  late StreamController<void> ticks;

  setUpAll(() => registerFallbackValue(const EmailParams(email: 'a')));

  setUp(() {
    resend = MockResendConfirmation();
    now = DateTime(2026, 10, 25, 12);
    store = ResendCooldownStore(() => now);
    ticks = StreamController<void>.broadcast();
  });

  tearDown(() => ticks.close());

  CheckEmailBloc build() => CheckEmailBloc(
    resendConfirmation: resend,
    cooldownStore: store,
    ticker: () => ticks.stream,
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'started with no email and no history stays empty',
    build: build,
    act: (bloc) => bloc.add(const CheckEmailStarted()),
    expect: () => <CheckEmailState>[],
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'started falls back to the last email of this run',
    build: build,
    setUp: () => store.start('a@b.co'),
    act: (bloc) => bloc.add(const CheckEmailStarted()),
    expect: () => [
      const CheckEmailState(email: 'a@b.co', remainingSeconds: 60),
    ],
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'started shows the remaining cooldown and counts down on ticks',
    build: build,
    setUp: () => store.start('a@b.co'),
    act: (bloc) async {
      bloc.add(const CheckEmailStarted(email: 'A@b.co'));
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(seconds: 25));
      ticks.add(null);
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(seconds: 35));
      ticks.add(null);
    },
    expect: () => [
      const CheckEmailState(email: 'a@b.co', remainingSeconds: 60),
      const CheckEmailState(email: 'a@b.co', remainingSeconds: 35),
      const CheckEmailState(email: 'a@b.co'),
    ],
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'started with an expired cooldown allows resend',
    build: build,
    setUp: () {
      store.start('a@b.co');
      now = now.add(const Duration(seconds: 61));
    },
    act: (bloc) => bloc.add(const CheckEmailStarted(email: 'a@b.co')),
    expect: () => [const CheckEmailState(email: 'a@b.co')],
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'resend success starts the cooldown',
    build: build,
    setUp: () => when(() => resend(any())).thenAnswer((_) async => right(unit)),
    act: (bloc) => bloc.add(const CheckEmailResendRequested(email: ' A@b.co ')),
    expect: () => [
      const CheckEmailState(status: SubmitStatus.loading),
      const CheckEmailState(
        status: SubmitStatus.success,
        email: 'a@b.co',
        remainingSeconds: 60,
      ),
    ],
    verify: (_) {
      verify(() => resend(const EmailParams(email: 'a@b.co'))).called(1);
      expect(store.remainingSeconds('a@b.co'), 60);
    },
  );

  final failures = <String, Failure>{
    'rate limit': const RateLimitFailure(),
    'network': const NetworkFailure('offline'),
    'unknown': const UnknownFailure('boom'),
  };
  failures.forEach((name, failure) {
    blocTest<CheckEmailBloc, CheckEmailState>(
      'resend failure ($name) does not start the cooldown',
      build: build,
      setUp: () =>
          when(() => resend(any())).thenAnswer((_) async => left(failure)),
      act: (bloc) => bloc.add(const CheckEmailResendRequested(email: 'a@b.co')),
      expect: () => [
        const CheckEmailState(status: SubmitStatus.loading),
        CheckEmailState(status: SubmitStatus.failure, failure: failure),
      ],
      verify: (_) => expect(store.remainingSeconds('a@b.co'), 0),
    );
  });

  blocTest<CheckEmailBloc, CheckEmailState>(
    'resend failure keeps the known email',
    build: build,
    seed: () => const CheckEmailState(email: 'a@b.co'),
    setUp: () =>
        when(() => resend(any()))
            .thenAnswer((_) async => left(const RateLimitFailure())),
    act: (bloc) => bloc.add(const CheckEmailResendRequested(email: 'a@b.co')),
    expect: () => [
      const CheckEmailState(status: SubmitStatus.loading, email: 'a@b.co'),
      const CheckEmailState(
        status: SubmitStatus.failure,
        failure: RateLimitFailure(),
        email: 'a@b.co',
      ),
    ],
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'invalid email makes no network call',
    build: build,
    act: (bloc) => bloc.add(const CheckEmailResendRequested(email: 'nope')),
    expect: () => <CheckEmailState>[],
    verify: (_) => verifyNever(() => resend(any())),
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'resend during the cooldown makes no network call',
    build: build,
    setUp: () => store.start('a@b.co'),
    act: (bloc) => bloc.add(const CheckEmailResendRequested(email: 'a@b.co')),
    expect: () => <CheckEmailState>[],
    verify: (_) => verifyNever(() => resend(any())),
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'cooldown ends after ticks following a successful resend',
    build: build,
    setUp: () => when(() => resend(any())).thenAnswer((_) async => right(unit)),
    act: (bloc) async {
      bloc.add(const CheckEmailResendRequested(email: 'a@b.co'));
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(seconds: 60));
      ticks.add(null);
    },
    skip: 2,
    expect: () => [
      const CheckEmailState(status: SubmitStatus.success, email: 'a@b.co'),
    ],
  );

  blocTest<CheckEmailBloc, CheckEmailState>(
    'dismissing the message returns to initial and keeps the cooldown',
    build: build,
    seed: () => const CheckEmailState(
      status: SubmitStatus.success,
      email: 'a@b.co',
      remainingSeconds: 30,
    ),
    act: (bloc) => bloc.add(const CheckEmailMessageDismissed()),
    expect: () => [
      const CheckEmailState(email: 'a@b.co', remainingSeconds: 30),
    ],
  );
}
