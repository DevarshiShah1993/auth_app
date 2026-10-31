import 'package:auth_app/core/widgets/inline_banner.dart';
import 'package:auth_app/core/widgets/inline_banner_variant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_host.dart';

void main() {
  testWidgets('renders message and default icon per variant', (tester) async {
    const expected = {
      InlineBannerVariant.error: Icons.error_outline,
      InlineBannerVariant.success: Icons.check_circle_outline,
      InlineBannerVariant.info: Icons.info_outline,
    };
    for (final entry in expected.entries) {
      await tester.pumpWidget(
        themedHost(InlineBanner(message: 'Hello', variant: entry.key)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byIcon(entry.value), findsOneWidget);
    }
  });

  testWidgets('action shows and fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      themedHost(
        InlineBanner(
          message: 'Unconfirmed',
          icon: Icons.mark_email_unread,
          actionLabel: 'Resend confirmation email',
          onAction: () => taps++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mark_email_unread), findsOneWidget);
    await tester.tap(find.text('Resend confirmation email'));
    expect(taps, 1);
  });

  testWidgets('no action without label and callback', (tester) async {
    await tester.pumpWidget(themedHost(const InlineBanner(message: 'Hi')));
    await tester.pumpAndSettle();
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('works in dark theme', (tester) async {
    await tester.pumpWidget(
      themedHost(const InlineBanner(message: 'Dark'), theme: ThemeData.dark()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);
  });
}
