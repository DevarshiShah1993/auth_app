import 'package:auth_app/core/theme/app_motion.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shown while the stored session is resolved on launch (AC-21).
class SplashPage extends StatelessWidget {
  /// Creates the splash page.
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    Widget tile = Container(
      width: spacing.xxl,
      height: spacing.xxl,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(spacing.radius),
      ),
      child: Icon(
        Icons.lock_outline,
        size: spacing.lg,
        color: context.appColors.primaryText,
      ),
    );
    if (!AppMotion.reduced(context)) {
      tile = tile.animate().fadeIn(duration: const Duration(milliseconds: 200));
    }

    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Loading',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile,
              SizedBox(height: spacing.lg),
              SizedBox.square(
                dimension: spacing.lg,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
