import 'package:auth_app/app.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/splash_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSessionBloc extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

void main() {
  testWidgets('App shows splash while the session resolves', (tester) async {
    final bloc = MockSessionBloc();
    whenListen(
      bloc,
      const Stream<AuthSessionState>.empty(),
      initialState: const AuthSessionState(),
    );
    await tester.pumpWidget(App(sessionBloc: bloc));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
