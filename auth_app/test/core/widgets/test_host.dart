import 'package:auth_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Wraps [child] in the app theme inside a Scaffold, for widget tests.
Widget themedHost(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(
      body: Center(child: SizedBox(width: 360, child: child)),
    ),
  );
}
