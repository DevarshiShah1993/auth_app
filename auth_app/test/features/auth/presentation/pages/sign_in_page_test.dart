import 'dart:async';

import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/core/error/email_not_confirmed_failure.dart';
import 'package:auth_app/core/error/invalid_credentials_failure.dart';
import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/rate_limit_failure.dart';
import 'package:auth_app/core/error/unknown_failure.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInWithPassword extends Mock implements SignInWithPassword {}

class MockSessionBloc extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

void main() {
  late MockSignInWithPassword signIn;
  late MockSessionBloc session;
  late SignInBloc bloc;
  late GoRouter router;
  late bool pumped;
  Object? checkEmailExtra;

  const user = AppUser(id: '1', email: 'a@b.co', emailConfirmed: true);

  setUpAll(() {
    registerFallbackValue(const EmailPasswordParams(email: 'a', password: 'b'));
    registerFallbackValue(const AuthSessionLinkResultConsumed());
  });

  setUp(() {
    signIn = MockSignInWithPassword();
    session = MockSessionBloc();
    checkEmailExtra = null;
    pumped = false;
    whenListen(
      session,
      const Stream<AuthSessionState>.empty(),
      initialState: const AuthSessionState(status: AuthSessionStatus.success),
    );
  });

  tearDown(() async {
    if (!pumped) return;
    router.dispose();
    await bloc.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    String? initialEmail,
    bool resize = true,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    pumped = true;
    bloc = SignInBloc(signIn: signIn);
    if (resize) {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<SignInBloc>.value(value: bloc),
              BlocProvider<AuthSessionBloc>.value(value: session),
            ],
            child: SignInPage(initialEmail: initialEmail),
          ),
        ),
        GoRoute(
          name: Routes.signUp,
          path: Routes.signUpPath,
          builder: (context, state) => const Text('SIGN UP STUB'),
        ),
        GoRoute(
          name: Routes.checkEmail,
          path: Routes.checkEmailPath,
          builder: (context, state) {
            checkEmailExtra = state.extra;
            return const Text('CHECK EMAIL STUB');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(field('Email'), 'User@Example.com');
    await tester.enterText(field('Password'), 'pw');
  }

  Future<void> tapSignIn(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
  }

  void failWith(Failure failure) {
    when(() => signIn(any())).thenAnswer((_) async => left(failure));
  }

  testWidgets('shows fields, button and sign up link (AC-14)', (tester) async {
    await pump(tester);
    expect(field('Email'), findsOneWidget);
    expect(field('Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.textContaining('Forgot'), findsNothing);
  });

  testWidgets('empty submit shows messages and makes no call (AC-15)', (
    tester,
  ) async {
    await pump(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    verifyNever(() => signIn(any()));
  });

  testWidgets('valid submit calls the use case with a normalised email', (
    tester,
  ) async {
    when(() => signIn(any())).thenAnswer((_) async => right(user));
    await pump(tester);
    await fillValid(tester);
    await tapSignIn(tester);
    await tester.pump(const Duration(milliseconds: 300));
    verify(
      () => signIn(
        const EmailPasswordParams(email: 'user@example.com', password: 'pw'),
      ),
    ).called(1);
  });

  testWidgets('loading disables fields and ignores a second submit (AC-16)', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(() => signIn(any())).thenAnswer((_) async {
      await completer.future;
      return right(user);
    });
    await pump(tester);
    await fillValid(tester);
    await tapSignIn(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(field('Email')).enabled, isFalse);
    expect(tester.widget<TextField>(field('Password')).enabled, isFalse);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    verify(() => signIn(any())).called(1);
    completer.complete();
    await tester.pump(const Duration(milliseconds: 300));
    // Success keeps the spinner until the router leaves the page.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('wrong credentials: banner, password cleared, email kept', (
    tester,
  ) async {
    failWith(const InvalidCredentialsFailure());
    await pump(tester);
    await fillValid(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password'), findsOneWidget);
    expect(tester.widget<TextField>(field('Password')).controller?.text, '');
    expect(
      tester.widget<TextField>(field('Email')).controller?.text,
      'User@Example.com',
    );
    expect(tester.widget<TextField>(field('Email')).enabled, isTrue);
  });

  testWidgets('rate limit, network and unknown show copy-table text', (
    tester,
  ) async {
    await pump(tester);
    await fillValid(tester);
    final cases = <(Failure, String)>[
      (const RateLimitFailure(), 'Too many attempts.'),
      (const NetworkFailure('x'), 'No connection.'),
      (const UnknownFailure('x'), 'Something went wrong.'),
    ];
    for (final (failure, text) in cases) {
      failWith(failure);
      await tapSignIn(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining(text), findsOneWidget);
      // Values are kept.
      expect(
        tester.widget<TextField>(field('Password')).controller?.text,
        'pw',
      );
    }
  });

  testWidgets('unconfirmed email shows resend action to check-email', (
    tester,
  ) async {
    failWith(const EmailNotConfirmedFailure());
    await pump(tester);
    await fillValid(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Please confirm your email before signing in'),
      findsOneWidget,
    );
    // Password is kept for this failure.
    expect(tester.widget<TextField>(field('Password')).controller?.text, 'pw');
    await tester.tap(
      find.widgetWithText(TextButton, 'Resend confirmation email'),
    );
    await tester.pumpAndSettle();
    expect(find.text('CHECK EMAIL STUB'), findsOneWidget);
    expect(checkEmailExtra, 'user@example.com');
  });

  testWidgets('editing a field dismisses the banner (AC-20)', (tester) async {
    failWith(const NetworkFailure('x'));
    await pump(tester);
    await fillValid(tester);
    await tapSignIn(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection'), findsOneWidget);
    await tester.enterText(field('Email'), 'other@example.com');
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection'), findsNothing);
  });

  testWidgets('confirmed link shows the banner once and consumes it', (
    tester,
  ) async {
    whenListen(
      session,
      const Stream<AuthSessionState>.empty(),
      initialState: const AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: EmailLinkResult.confirmed,
      ),
    );
    await pump(tester);
    expect(find.text('Email confirmed. You can now sign in.'), findsOneWidget);
    verify(() => session.add(const AuthSessionLinkResultConsumed())).called(1);
    await tester.enterText(field('Email'), 'a@b.co');
    await tester.pumpAndSettle();
    expect(find.text('Email confirmed. You can now sign in.'), findsNothing);
  });

  testWidgets('link confirmed while the page is open shows the banner', (
    tester,
  ) async {
    final controller = StreamController<AuthSessionState>();
    addTearDown(controller.close);
    whenListen(
      session,
      controller.stream,
      initialState: const AuthSessionState(status: AuthSessionStatus.success),
    );
    await pump(tester);
    expect(find.textContaining('Email confirmed'), findsNothing);
    controller.add(
      const AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: EmailLinkResult.confirmed,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Email confirmed. You can now sign in.'), findsOneWidget);
    verify(() => session.add(const AuthSessionLinkResultConsumed())).called(1);
  });

  testWidgets('no banner and no consume without a link result', (tester) async {
    await pump(tester);
    expect(find.textContaining('Email confirmed'), findsNothing);
    verifyNever(() => session.add(any()));
  });

  testWidgets('prefills the email from the route extra', (tester) async {
    await pump(tester, initialEmail: 'prefilled@example.com');
    expect(
      tester.widget<TextField>(field('Email')).controller?.text,
      'prefilled@example.com',
    );
  });

  testWidgets('Sign up link goes to sign up', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('SIGN UP STUB'), findsOneWidget);
  });

  testWidgets('password toggle reveals and hides text', (tester) async {
    await pump(tester);
    expect(tester.widget<TextField>(field('Password')).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(field('Password')).obscureText, isFalse);
  });

  testWidgets('no overflow on 360x640 with keyboard open', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await pump(tester, resize: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in dark theme without errors', (tester) async {
    await pump(tester, themeMode: ThemeMode.dark);
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });
}
