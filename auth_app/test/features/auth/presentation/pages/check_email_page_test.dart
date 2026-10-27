import 'dart:async';

import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/rate_limit_failure.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_params.dart';
import 'package:auth_app/features/auth/domain/usecases/resend_confirmation.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/check_email_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/check_email_page.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockResendConfirmation extends Mock implements ResendConfirmation {}

class MockSessionBloc extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

void main() {
  late MockResendConfirmation resend;
  late MockSessionBloc session;
  late DateTime now;
  late ResendCooldownStore store;
  late StreamController<void> ticks;
  late CheckEmailBloc bloc;
  late GoRouter router;

  setUpAll(() {
    registerFallbackValue(const EmailParams(email: 'a'));
    registerFallbackValue(const AuthSessionLinkResultConsumed());
  });

  setUp(() {
    resend = MockResendConfirmation();
    session = MockSessionBloc();
    now = DateTime(2026, 10, 25, 12);
    store = ResendCooldownStore(() => now);
    ticks = StreamController<void>.broadcast();
  });

  tearDown(() async {
    router.dispose();
    await bloc.close();
    await ticks.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    String? email,
    EmailLinkResult? linkResult,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(
      session,
      const Stream<AuthSessionState>.empty(),
      initialState: AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: linkResult,
      ),
    );
    // Created inside the test body so its microtasks run in the fake zone.
    bloc = CheckEmailBloc(
      resendConfirmation: resend,
      cooldownStore: store,
      ticker: () => ticks.stream,
    )..add(CheckEmailStarted(email: email));
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthSessionBloc>.value(value: session),
              BlocProvider<CheckEmailBloc>.value(value: bloc),
            ],
            child: const CheckEmailPage(),
          ),
        ),
        GoRoute(
          name: Routes.signIn,
          path: Routes.signInPath,
          builder: (context, state) => const Text('SIGN IN STUB'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Finder resendButton(String label) =>
      find.widgetWithText(OutlinedButton, label);

  testWidgets('normal variant shows email, resend and back (AC-07)', (
    tester,
  ) async {
    await pump(tester, email: 'user@example.com');
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('We sent a confirmation link to'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(resendButton('Resend email'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    verifyNever(() => session.add(any()));
  });

  testWidgets('resend sends, shows success, starts a disabled countdown', (
    tester,
  ) async {
    when(() => resend(any())).thenAnswer((_) async => right(unit));
    await pump(tester, email: 'user@example.com');
    await tester.tap(resendButton('Resend email'));
    await tester.pumpAndSettle();
    verify(() => resend(const EmailParams(email: 'user@example.com')))
        .called(1);
    expect(find.text('Confirmation email sent'), findsOneWidget);
    expect(resendButton('Resend email in 1:00'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(resendButton('Resend email in 1:00'))
          .onPressed,
      isNull,
    );
    // Banner auto-dismisses after 5 s.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Confirmation email sent'), findsNothing);
  });

  testWidgets('arriving during a cooldown shows the countdown and re-enables', (
    tester,
  ) async {
    store.start('user@example.com');
    now = now.add(const Duration(seconds: 18));
    await pump(tester, email: 'user@example.com');
    final disabled = resendButton('Resend email in 0:42');
    expect(disabled, findsOneWidget);
    expect(tester.widget<OutlinedButton>(disabled).onPressed, isNull);
    await tester.tap(disabled, warnIfMissed: false);
    await tester.pump();
    verifyNever(() => resend(any()));

    now = now.add(const Duration(seconds: 42));
    ticks.add(null);
    await tester.pumpAndSettle();
    final enabled = resendButton('Resend email');
    expect(tester.widget<OutlinedButton>(enabled).onPressed, isNotNull);
  });

  testWidgets('rate limit and network failures show a banner, no cooldown', (
    tester,
  ) async {
    when(() => resend(any()))
        .thenAnswer((_) async => left(const RateLimitFailure()));
    await pump(tester, email: 'user@example.com');
    await tester.tap(resendButton('Resend email'));
    await tester.pumpAndSettle();
    expect(
      find.text('Too many attempts. Please wait a moment and try again.'),
      findsOneWidget,
    );
    expect(resendButton('Resend email'), findsOneWidget);

    when(() => resend(any()))
        .thenAnswer((_) async => left(const NetworkFailure('x')));
    await tester.tap(resendButton('Resend email'));
    await tester.pumpAndSettle();
    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
    expect(store.remainingSeconds('user@example.com'), 0);
  });

  testWidgets('loading shows a spinner on the button', (tester) async {
    final completer = Completer<void>();
    when(() => resend(any())).thenAnswer((_) async {
      await completer.future;
      return right(unit);
    });
    await pump(tester, email: 'user@example.com');
    await tester.tap(resendButton('Resend email'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete();
    await tester.pumpAndSettle();
    // Let the success banner timer elapse.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('expired variant with known email (AC-13a)', (tester) async {
    store.start('user@example.com');
    await pump(
      tester,
      email: 'user@example.com',
      linkResult: EmailLinkResult.invalid,
    );
    expect(find.text('Link expired'), findsOneWidget);
    expect(find.text('This link is invalid or has expired'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Back to sign in'), findsOneWidget);
    verify(() => session.add(const AuthSessionLinkResultConsumed())).called(1);
  });

  testWidgets('expired variant, unknown email: field, validation, resend', (
    tester,
  ) async {
    when(() => resend(any())).thenAnswer((_) async => right(unit));
    await pump(tester, linkResult: EmailLinkResult.invalid);
    expect(find.text('This link is invalid or has expired'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Invalid email: message shown, no network call (AC-13c).
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(resendButton('Resend email'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    verifyNever(() => resend(any()));

    await tester.enterText(find.byType(TextField), ' New@Example.com ');
    await tester.tap(resendButton('Resend email'));
    await tester.pumpAndSettle();
    verify(() => resend(const EmailParams(email: 'new@example.com'))).called(1);
    // Switches to the normal variant with the address and the countdown.
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('new@example.com'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(resendButton('Resend email in 1:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Back to sign in navigates to sign in (AC-13e)', (tester) async {
    await pump(tester, linkResult: EmailLinkResult.invalid);
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('SIGN IN STUB'), findsOneWidget);
  });

  testWidgets('no overflow on 360x640 with keyboard open (expired variant)', (
    tester,
  ) async {
    await pump(tester, linkResult: EmailLinkResult.invalid);
    tester.view.physicalSize = const Size(360, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(resendButton('Resend email'));
    expect(tester.takeException(), isNull);
  });
}
