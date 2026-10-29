// QA (T-09): router/session edge cases (AC-17, AC-23, AC-24, AC-26, AC-27,
// AC-12) driven by a controllable AuthSessionBloc stream.
import 'dart:async';

import 'package:auth_app/core/di/injection.dart';
import 'package:auth_app/core/router/app_router.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/router/stream_refresh_listenable.dart';
import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/domain/usecases/resend_confirmation.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:auth_app/features/auth/domain/usecases/sign_up.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/check_email_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:auth_app/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/check_email_page.dart';
import 'package:auth_app/features/auth/presentation/pages/home_page.dart';
import 'package:auth_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:auth_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:auth_app/features/auth/presentation/services/resend_cooldown_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionBloc extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

class _MockResend extends Mock implements ResendConfirmation {}

class _MockSignIn extends Mock implements SignInWithPassword {}

class _MockSignUp extends Mock implements SignUp {}

void main() {
  const user = AppUser(id: '1', email: 'a@b.co', emailConfirmed: true);
  const signedOut = AuthSessionState(status: AuthSessionStatus.success);
  const signedIn = AuthSessionState(
    status: AuthSessionStatus.success,
    user: user,
  );
  late _MockSessionBloc bloc;
  late StreamController<AuthSessionState> states;
  late StreamRefreshListenable refresh;
  late GoRouter router;

  Future<void> pump(WidgetTester tester, AuthSessionState initial) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    states = StreamController<AuthSessionState>.broadcast();
    addTearDown(states.close);
    whenListen(bloc, states.stream, initialState: initial);
    refresh = StreamRefreshListenable(bloc.stream);
    router = createRouter(sessionBloc: bloc, refreshListenable: refresh);
    await tester.pumpWidget(
      BlocProvider<AuthSessionBloc>.value(
        value: bloc,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Emits [next] as the bloc's new state (state getter and stream).
  Future<void> emit(WidgetTester tester, AuthSessionState next) async {
    when(() => bloc.state).thenReturn(next);
    states.add(next);
    await tester.pumpAndSettle();
  }

  setUp(() {
    bloc = _MockSessionBloc();
    sl
      ..registerFactory<SignInBloc>(() => SignInBloc(signIn: _MockSignIn()))
      ..registerFactory<SignUpBloc>(
        () => SignUpBloc(
          signUp: _MockSignUp(),
          cooldownStore: ResendCooldownStore(),
        ),
      )
      ..registerFactory<CheckEmailBloc>(
        () => CheckEmailBloc(
          resendConfirmation: _MockResend(),
          cooldownStore: ResendCooldownStore(),
        ),
      );
  });

  tearDown(() async {
    await sl.reset();
    router.dispose();
    refresh.dispose();
  });

  testWidgets('AC-23: unauthenticated user can reach the three public routes', (
    tester,
  ) async {
    await pump(tester, signedOut);
    router.go(Routes.signUpPath);
    await tester.pumpAndSettle();
    expect(find.byType(SignUpPage), findsOneWidget);
    router.go(Routes.checkEmailPath);
    await tester.pumpAndSettle();
    expect(find.byType(CheckEmailPage), findsOneWidget);
  });

  testWidgets('AC-23: unknown route while signed out goes to sign in', (
    tester,
  ) async {
    await pump(tester, signedOut);
    router.go('/does-not-exist');
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets(
    'AC-24: signed-in user is redirected from sign-up and check-email',
    (tester) async {
      await pump(tester, signedIn);
      router.go(Routes.signUpPath);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      router.go(Routes.checkEmailPath);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  testWidgets('AC-17: after sign-in the stack cannot pop back to Sign In', (
    tester,
  ) async {
    await pump(tester, signedOut);
    expect(find.byType(SignInPage), findsOneWidget);
    await emit(tester, signedIn);
    expect(find.byType(HomePage), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets(
    'AC-26/AC-27: session ending moves Home to Sign In, no way back',
    (tester) async {
      await pump(tester, signedIn);
      expect(find.byType(HomePage), findsOneWidget);
      await emit(tester, signedOut);
      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(router.canPop(), isFalse);
      router.go(Routes.homePath);
      await tester.pumpAndSettle();
      expect(find.byType(SignInPage), findsOneWidget);
    },
  );

  testWidgets('AC-12: confirmed link while on Sign Up lands on Sign In', (
    tester,
  ) async {
    await pump(tester, signedOut);
    router.go(Routes.signUpPath);
    await tester.pumpAndSettle();
    await emit(
      tester,
      const AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: EmailLinkResult.confirmed,
      ),
    );
    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('invalid link while signed in does not navigate', (tester) async {
    await pump(tester, signedIn);
    await emit(
      tester,
      const AuthSessionState(
        status: AuthSessionStatus.success,
        user: user,
        linkResult: EmailLinkResult.invalid,
      ),
    );
    expect(find.byType(HomePage), findsOneWidget);
  });
}
