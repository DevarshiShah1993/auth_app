import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/core/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required Widget child, MediaQueryData? media}) {
  Widget home = AuthScaffold(child: child);
  if (media != null) home = MediaQuery(data: media, child: home);
  return MaterialApp(theme: AppTheme.light, home: home);
}

void main() {
  testWidgets('renders child and caps width at 400', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(child: const SizedBox(key: Key('c'), width: 1000, height: 50)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('c'))).width, 400);
  });

  testWidgets('small phone with keyboard open scrolls without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        child: Column(
          children: [for (var i = 0; i < 8; i++) const SizedBox(height: 80)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('survives text scale 1.3', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child ?? const SizedBox(),
        ),
        home: const AuthScaffold(child: Text('Hello')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
