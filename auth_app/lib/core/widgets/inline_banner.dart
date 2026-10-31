import 'package:auth_app/core/theme/app_motion.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:auth_app/core/widgets/inline_banner_variant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Banner with icon, message and an optional text action. Announced to
/// screen readers as a live region.
class InlineBanner extends StatelessWidget {
  /// Creates a banner.
  const InlineBanner({
    required this.message,
    super.key,
    this.variant = InlineBannerVariant.error,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  /// Banner text.
  final String message;

  /// Error, success or info styling.
  final InlineBannerVariant variant;

  /// Overrides the default leading icon.
  final IconData? icon;

  /// Label of the optional trailing action.
  final String? actionLabel;

  /// Action callback; the action shows only when both label and callback exist.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
    final spacing = context.spacing;

    final (fill, accent, textColor, defaultIcon) = switch (variant) {
      InlineBannerVariant.error => (
        scheme.errorContainer,
        scheme.error,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
      InlineBannerVariant.success => (
        colors.successContainer,
        colors.success,
        colors.successText,
        Icons.check_circle_outline,
      ),
      InlineBannerVariant.info => (
        scheme.primaryContainer,
        scheme.primary,
        scheme.onPrimaryContainer,
        Icons.info_outline,
      ),
    };

    final action = (actionLabel != null && onAction != null)
        ? TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: textColor),
            child: Text(actionLabel ?? ''),
          )
        : null;

    final banner = Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(spacing.radius),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.md - spacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon ?? defaultIcon, size: 20, color: accent),
              ),
              SizedBox(width: spacing.sm + spacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (AppMotion.reduced(context)) return banner;
    return banner
        .animate()
        .fadeIn(duration: AppMotion.errorIn)
        .slideY(
          begin: -0.1,
          end: 0,
          duration: AppMotion.errorIn,
          curve: AppMotion.curve,
        );
  }
}
