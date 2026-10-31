// QA (T-09): AC-30 for Check Your Email normal variant (small phone,
// keyboard-free, large text, dark theme) and AC-13c invalid email.
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
import 'package:mocktail/mocktail.dart';

class _MockResend extends Mock implements ResendConfirmation {}

class _MockSession extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

void main() {
  late _MockResend resend;
  late _MockSession session;
  late CheckEmailBloc bloc;

  setUpAll(() => registerFallbackValue(const EmailParams(email: 'a')));

  setUp(() {
    resend = _MockResend();
    session = _MockSession();
    whenListen(
      session,
      const Stream<AuthSessionState>.empty(),
      initialState: const AuthSessionState(status: AuthSessionStatus.success),
    );
  });

  tearDown(() => bloc.close());

  Future<void> pump(
    WidgetTester tester, {
    String? email,
    ThemeMode mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    bloc = CheckEmailBloc(
      resendConfirmation: resend,
      cooldownStore: ResendCooldownStore(),
    )..add(CheckEmailStarted(email: email));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthSessionBloc>.value(value: session),
            BlocProvider<CheckEmailBloc>.value(value: bloc),
          ],
          child: const CheckEmailPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('normal variant: no overflow at 360x640 + keyboard, $mode', (
      tester,
    ) async {
      await pump(tester, email: 'someone@example.com', mode: mode);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Back to sign in'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('normal variant survives a very long address', (tester) async {
    await pump(tester, email: '${'a' * 60}@very-long-domain-name-example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AC-13c: invalid email in the unknown-email variant makes no call',
    (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'not-an-email');
      final button = find.widgetWithText(OutlinedButton, 'Resend email');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      verifyNever(() => resend(any()));
    },
  );
}
