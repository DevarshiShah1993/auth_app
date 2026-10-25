import 'package:auth_app/core/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

/// PLACEHOLDER for T-07: only a title so routing can be tested.
class SignUpPage extends StatelessWidget {
  /// Creates the placeholder page.
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Text(
        'Sign up',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
