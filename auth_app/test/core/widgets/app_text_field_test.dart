import 'package:auth_app/core/utils/validators.dart';
import 'package:auth_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_host.dart';

void main() {
  testWidgets('renders label and accepts input', (tester) async {
    String? changed;
    await tester.pumpWidget(
      themedHost(AppTextField(label: 'Email', onChanged: (v) => changed = v)),
    );
    expect(find.text('Email'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a@b.co');
    expect(changed, 'a@b.co');
  });

  testWidgets('shows external errorText with icon', (tester) async {
    await tester.pumpWidget(
      themedHost(const AppTextField(label: 'Email', errorText: 'Bad email')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bad email'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('validate() shows error, edit clears it', (tester) async {
    final key = GlobalKey<AppTextFieldState>();
    await tester.pumpWidget(
      themedHost(
        AppTextField(
          key: key,
          label: 'Email',
          validator: (v) => Validators.email(v),
        ),
      ),
    );
    expect(key.currentState?.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a@b.co');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsNothing);
    expect(key.currentState?.validate(), isTrue);
  });

  testWidgets('validates on blur', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      themedHost(
        AppTextField(
          label: 'Email',
          focusNode: focus,
          validator: (v) => Validators.email(v),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'nope');
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('disabled field ignores input', (tester) async {
    await tester.pumpWidget(
      themedHost(const AppTextField(label: 'Email', enabled: false)),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('shows helper text until an error replaces it', (tester) async {
    final key = GlobalKey<AppTextFieldState>();
    await tester.pumpWidget(
      themedHost(
        AppTextField(
          key: key,
          label: 'Password',
          helperText: 'Hint text',
          validator: Validators.newPassword,
        ),
      ),
    );
    expect(find.text('Hint text'), findsOneWidget);
    key.currentState?.validate();
    await tester.pumpAndSettle();
    expect(find.text('Hint text'), findsNothing);
  });

  testWidgets('showErrorBorder shows the error border without error text', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedHost(
        const AppTextField(
          label: 'Password',
          helperText: 'Hint text',
          showErrorBorder: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TextField));
    final theme = Theme.of(context).inputDecorationTheme;
    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.enabledBorder, theme.errorBorder);
    expect(decoration.focusedBorder, theme.focusedErrorBorder);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('Hint text'), findsOneWidget);
  });

  testWidgets('default state keeps the normal border', (tester) async {
    await tester.pumpWidget(themedHost(const AppTextField(label: 'Email')));
    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.enabledBorder, isNull);
  });
}
