import 'package:auth_app/core/router/app_router.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/core/router/stream_refresh_listenable.dart';
import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/check_email_page.dart';
import 'package:auth_app/features/auth/presentation/pages/home_page.dart';
import 'package:auth_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:auth_app/features/auth/presentation/pages/splash_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class MockSessionBloc extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

void main() {
  const user = AppUser(id: '1', email: 'a@b.co', emailConfirmed: true);
  late MockSessionBloc bloc;
  late StreamRefreshListenable refresh;
  late GoRouter router;

  Future<void> pump(WidgetTester tester, AuthSessionState initial) async {
    whenListen(
      bloc,
      const Stream<AuthSessionState>.empty(),
      initialState: initial,
    );
    refresh = StreamRefreshListenable(bloc.stream);
    router = createRouter(sessionBloc: bloc, refreshListenable: refresh);
    await tester.pumpWidget(
      BlocProvider<AuthSessionBloc>.value(
        value: bloc,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  setUp(() => bloc = MockSessionBloc());

  tearDown(() {
    router.dispose();
    refresh.dispose();
  });

  testWidgets('shows splash while resolving', (tester) async {
    await pump(tester, const AuthSessionState());
    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('unauthenticated goes to sign in', (tester) async {
    await pump(
      tester,
      const AuthSessionState(status: AuthSessionStatus.success),
    );
    expect(find.byType(SignInPage), findsOneWidget);
    router.go(Routes.homePath);
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('authenticated goes to home and is kept away from sign in', (
    tester,
  ) async {
    await pump(
      tester,
      const AuthSessionState(status: AuthSessionStatus.success, user: user),
    );
    expect(find.byType(HomePage), findsOneWidget);
    router.goNamed(Routes.signIn);
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
  });

  testWidgets('navigates from splash to sign in when state resolves', (
    tester,
  ) async {
    whenListen(
      bloc,
      Stream.value(const AuthSessionState(status: AuthSessionStatus.success)),
      initialState: const AuthSessionState(),
    );
    refresh = StreamRefreshListenable(bloc.stream);
    router = createRouter(sessionBloc: bloc, refreshListenable: refresh);
    await tester.pumpWidget(
      BlocProvider<AuthSessionBloc>.value(
        value: bloc,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('invalid link result opens check email once', (tester) async {
    await pump(
      tester,
      const AuthSessionState(
        status: AuthSessionStatus.success,
        linkResult: EmailLinkResult.invalid,
      ),
    );
    expect(find.byType(CheckEmailPage), findsOneWidget);
    router.goNamed(Routes.signIn);
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  });
}
