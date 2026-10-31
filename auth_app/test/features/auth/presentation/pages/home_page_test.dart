import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/home_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionBloc extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

void main() {
  const user = AppUser(id: '1', email: 'a@b.co', emailConfirmed: true);
  const signedIn = AuthSessionState(
    status: AuthSessionStatus.success,
    user: user,
  );
  late MockSessionBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthSessionStarted()));

  setUp(() {
    bloc = MockSessionBloc();
    when(() => bloc.state).thenReturn(signedIn);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthSessionBloc>.value(
        value: bloc,
        child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows title, hamburger and centered email only', (tester) async {
    await pump(tester);
    expect(find.text('Bakery ERP'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Log out'), findsNothing);
    final email = find.text('a@b.co');
    expect(email, findsOneWidget);
    final screen = tester.getSize(find.byType(Scaffold));
    final center = tester.getCenter(email);
    expect(center.dx, closeTo(screen.width / 2, 1));
    final body = tester.getRect(find.byType(Center).first);
    expect(body.center.dx, closeTo(screen.width / 2, 1));
  });

  testWidgets('hamburger opens drawer containing Log out', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('Log out dispatches logout', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pump();
    verify(() => bloc.add(const AuthSessionLogoutRequested())).called(1);
  });

  testWidgets('drawer closes when logout finishes', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [
        AuthSessionState(status: AuthSessionStatus.loading, user: user),
        AuthSessionState(status: AuthSessionStatus.success),
      ]),
      initialState: signedIn,
    );
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Log out'), findsNothing);
  });
}
