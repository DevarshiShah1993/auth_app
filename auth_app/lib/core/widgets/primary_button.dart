import 'package:auth_app/core/theme/app_motion.dart';
import 'package:auth_app/core/widgets/primary_button_variant.dart';
import 'package:flutter/material.dart';

/// Full-width 48dp button with a loading state.
///
/// While [isLoading] the button keeps its look and size, ignores taps and
/// swaps the label for a 20dp spinner. A null [onPressed] disables it.
class PrimaryButton extends StatelessWidget {
  /// Creates a button.
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.variant = PrimaryButtonVariant.filled,
  });

  /// Button text.
  final String label;

  /// Tap callback; null disables the button.
  final VoidCallback? onPressed;

  /// Shows the spinner and ignores taps.
  final bool isLoading;

  /// Optional leading icon.
  final IconData? icon;

  /// Filled (default) or outlined.
  final PrimaryButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spinnerColor = variant == PrimaryButtonVariant.filled
        ? scheme.onPrimary
        : scheme.primary;
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.buttonLoading;

    final content = AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.curve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: isLoading
          ? Semantics(
              key: const ValueKey<String>('loading'),
              label: '$label, loading',
              liveRegion: true,
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: spinnerColor,
                ),
              ),
            )
          : Row(
              key: const ValueKey<String>('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ],
            ),
    );

    // Keeps the enabled look while loading; the no-op blocks double submit.
    final VoidCallback? effective = isLoading ? () {} : onPressed;

    return switch (variant) {
      PrimaryButtonVariant.filled => FilledButton(
        onPressed: effective,
        child: content,
      ),
      PrimaryButtonVariant.outlined => OutlinedButton(
        onPressed: effective,
        child: content,
      ),
    };
  }
}
