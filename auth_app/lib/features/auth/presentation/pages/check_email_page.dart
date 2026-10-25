import 'package:auth_app/core/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';

/// PLACEHOLDER for T-07: only a title so routing can be tested.
class CheckEmailPage extends StatelessWidget {
  /// Creates the placeholder page.
  const CheckEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Text(
        'Check your email',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
