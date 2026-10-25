import 'package:auth_app/core/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

/// PLACEHOLDER for T-08: only a title so routing can be tested.
class SignInPage extends StatelessWidget {
  /// Creates the placeholder page.
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Text(
        'Sign in',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
