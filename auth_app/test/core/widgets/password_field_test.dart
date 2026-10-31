import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/core/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_host.dart';

bool _obscured(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).obscureText;

void main() {
  testWidgets('is hidden by default and toggles visibility', (tester) async {
    await tester.pumpWidget(themedHost(const PasswordField(label: 'Password')));
    expect(_obscured(tester), isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(_obscured(tester), isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(_obscured(tester), isTrue);
  });

  testWidgets('toggle has a 48dp hit target', (tester) async {
    await tester.pumpWidget(themedHost(const PasswordField(label: 'Password')));
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('visibility resets when the field is rebuilt anew', (
    tester,
  ) async {
    await tester.pumpWidget(themedHost(const PasswordField(label: 'Password')));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(themedHost(const PasswordField(label: 'Password')));
    expect(_obscured(tester), isTrue);
  });

  testWidgets('validate() shows the validator error', (tester) async {
    final key = GlobalKey<PasswordFieldState>();
    await tester.pumpWidget(
      themedHost(
        PasswordField(
          key: key,
          label: 'Password',
          validator: Validators.requiredPassword,
        ),
      ),
    );
    expect(key.currentState?.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('disabled field disables the toggle', (tester) async {
    await tester.pumpWidget(
      themedHost(const PasswordField(label: 'Password', enabled: false)),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
