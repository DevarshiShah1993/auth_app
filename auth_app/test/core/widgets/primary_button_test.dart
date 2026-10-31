import 'package:auth_app/core/widgets/primary_button.dart';
import 'package:auth_app/core/widgets/primary_button_variant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_host.dart';

void main() {
  testWidgets('renders label and calls onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      themedHost(PrimaryButton(label: 'Sign in', onPressed: () => taps++)),
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height, 48);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);
  });

  testWidgets('loading shows spinner and ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      themedHost(
        PrimaryButton(
          label: 'Sign in',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
    expect(find.bySemanticsLabel('Sign in, loading'), findsOneWidget);
  });

  testWidgets('size does not change while loading', (tester) async {
    Future<Size> sizeFor(bool loading) async {
      await tester.pumpWidget(
        themedHost(
          PrimaryButton(label: 'Sign in', isLoading: loading, onPressed: () {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      return tester.getSize(find.byType(FilledButton));
    }

    expect(await sizeFor(true), await sizeFor(false));
  });

  testWidgets('null onPressed disables the button', (tester) async {
    await tester.pumpWidget(
      themedHost(const PrimaryButton(label: 'Sign in', onPressed: null)),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isFalse,
    );
  });

  testWidgets('outlined variant renders an OutlinedButton', (tester) async {
    await tester.pumpWidget(
      themedHost(
        PrimaryButton(
          label: 'Resend email',
          variant: PrimaryButtonVariant.outlined,
          onPressed: () {},
        ),
      ),
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('shows optional icon', (tester) async {
    await tester.pumpWidget(
      themedHost(
        PrimaryButton(label: 'Go', icon: Icons.login, onPressed: () {}),
      ),
    );
    expect(find.byIcon(Icons.login), findsOneWidget);
  });
}
