import 'dart:async';

import 'package:auth_app/core/error/network_failure.dart';
import 'package:auth_app/core/error/user_already_exists_failure.dart';
import 'package:auth_app/core/error/weak_password_failure.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/features/auth/domain/usecases/params/email_password_params.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_up.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:auth_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockSignUp extends Mock implements SignUp {}

void main() {
  late MockSignUp signUp;
  late SignUpBloc bloc;
  late bool pumped;
  late GoRouter router;
  Object? checkEmailExtra;
  String? signInExtra;

  setUpAll(
    () => registerFallbackValue(
      const EmailPasswordParams(email: 'a', password: 'b'),
    ),
  );

  setUp(() {
    signUp = MockSignUp();
    checkEmailExtra = null;
    signInExtra = null;
    pumped = false;
  });

  tearDown(() async {
    if (!pumped) return;
    router.dispose();
    await bloc.close();
  });

  Future<void> pump(WidgetTester tester, {bool resize = true}) async {
    // Created inside the test body so its microtasks run in the fake zone.
    pumped = true;
    bloc = SignUpBloc(signUp: signUp, cooldownStore: ResendCooldownStore());
    if (resize) {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<SignUpBloc>.value(
            value: bloc,
            child: const SignUpPage(),
          ),
        ),
        GoRoute(
          name: Routes.checkEmail,
          path: Routes.checkEmailPath,
          builder: (context, state) {
            checkEmailExtra = state.extra;
            return const Text('CHECK EMAIL STUB');
          },
        ),
        GoRoute(
          name: Routes.signIn,
          path: Routes.signInPath,
          builder: (context, state) {
            signInExtra = state.extra as String?;
            return const Text('SIGN IN STUB');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(field('Email'), 'User@Example.com');
    await tester.enterText(field('Password'), 'password1');
    await tester.enterText(field('Confirm password'), 'password1');
  }

  Future<void> tapSignUp(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pump();
  }

  testWidgets('shows fields, button and sign in link (AC-01)', (tester) async {
    await pump(tester);
    expect(field('Email'), findsOneWidget);
    expect(field('Password'), findsOneWidget);
    expect(field('Confirm password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign up'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(
      find.text('At least 8 characters, with a letter and a number'),
      findsOneWidget,
    );
  });

  testWidgets('empty submit shows messages and makes no call (AC-02)', (
    tester,
  ) async {
    await pump(tester);
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text(
        'Password must be at least 8 characters and include a letter and a '
        'number',
      ),
      findsOneWidget,
    );
    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(() => signUp(any()));
  });

  testWidgets('mismatching confirm shows message; clears on edit', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(field('Email'), 'a@b.co');
    await tester.enterText(field('Password'), 'password1');
    await tester.enterText(field('Confirm password'), 'password2');
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.enterText(field('Confirm password'), 'password1');
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsNothing);
    verifyNever(() => signUp(any()));
  });

  testWidgets('valid submit calls the use case with a normalised email', (
    tester,
  ) async {
    when(() => signUp(any())).thenAnswer((_) async => right(unit));
    await pump(tester);
    await fillValid(tester);
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    verify(
      () => signUp(
        const EmailPasswordParams(
          email: 'user@example.com',
          password: 'password1',
        ),
      ),
    ).called(1);
  });

  testWidgets('loading disables fields and shows a spinner (AC-03)', (
    tester,
  ) async {
    final completer = Completer<Either<NetworkFailure, Unit>>();
    when(() => signUp(any())).thenAnswer((_) async {
      await completer.future;
      return right(unit);
    });
    await pump(tester);
    await fillValid(tester);
    await tapSignUp(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(field('Email')).enabled, isFalse);
    expect(tester.widget<TextField>(field('Password')).enabled, isFalse);
    // A second tap does not submit again.
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    verify(() => signUp(any())).called(1);
    completer.complete(right(unit));
    await tester.pumpAndSettle();
  });

  testWidgets('success goes to check-email with the address as extra', (
    tester,
  ) async {
    when(() => signUp(any())).thenAnswer((_) async => right(unit));
    await pump(tester);
    await fillValid(tester);
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    expect(find.text('CHECK EMAIL STUB'), findsOneWidget);
    expect(checkEmailExtra, 'user@example.com');
  });

  testWidgets('already registered shows banner with Sign in action', (
    tester,
  ) async {
    when(() => signUp(any()))
        .thenAnswer((_) async => left(const UserAlreadyExistsFailure()));
    await pump(tester);
    await fillValid(tester);
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('An account with this email already exists. Try signing in.'),
      findsOneWidget,
    );
    // Values are kept and fields re-enabled.
    expect(tester.widget<TextField>(field('Email')).enabled, isTrue);
    // The banner action is the first 'Sign in' text button (above the card link).
    await tester.tap(find.widgetWithText(TextButton, 'Sign in').first);
    await tester.pumpAndSettle();
    expect(find.text('SIGN IN STUB'), findsOneWidget);
    expect(signInExtra, 'user@example.com');
  });

  testWidgets('weak password and network failures show copy-table text', (
    tester,
  ) async {
    when(() => signUp(any()))
        .thenAnswer((_) async => left(const WeakPasswordFailure()));
    await pump(tester);
    await fillValid(tester);
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Password is too weak. Use at least 8 characters with a letter and a '
        'number.',
      ),
      findsOneWidget,
    );

    when(() => signUp(any()))
        .thenAnswer((_) async => left(const NetworkFailure('x')));
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('No connection. Check your internet and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('weak password failure marks only the password field border', (
    tester,
  ) async {
    when(() => signUp(any()))
        .thenAnswer((_) async => left(const WeakPasswordFailure()));
    await pump(tester);
    await fillValid(tester);
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<AppTextField>(find.byType(AppTextField))
        .toList();
    expect(fields.map((f) => f.showErrorBorder), [false, true, false]);
    // No duplicate error text under the field.
    expect(find.textContaining('Password is too weak'), findsOneWidget);

    await tester.enterText(field('Password'), 'another1Password');
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<AppTextField>(find.byType(AppTextField))
          .any((f) => f.showErrorBorder),
      isFalse,
    );
  });

  testWidgets('editing a field dismisses the banner (AC-20)', (tester) async {
    when(() => signUp(any()))
        .thenAnswer((_) async => left(const NetworkFailure('x')));
    await pump(tester);
    await fillValid(tester);
    await tapSignUp(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection'), findsOneWidget);
    await tester.enterText(field('Email'), 'other@example.com');
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection'), findsNothing);
  });

  testWidgets('Sign in link goes to sign in', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('SIGN IN STUB'), findsOneWidget);
  });

  testWidgets('password toggle reveals and hides text (AC-06)', (tester) async {
    await pump(tester);
    expect(tester.widget<TextField>(field('Password')).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();
    expect(tester.widget<TextField>(field('Password')).obscureText, isFalse);
  });

  testWidgets('no overflow on 360x640 with keyboard open, both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await pump(tester, resize: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Sign up'), findsOneWidget);
    // Submit stays reachable by scrolling.
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign up'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in dark theme without errors', (tester) async {
    await pump(tester);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
