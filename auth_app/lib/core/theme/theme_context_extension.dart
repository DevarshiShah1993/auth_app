import 'package:auth_app/core/theme/app_colors.dart';
import 'package:auth_app/core/theme/app_spacing.dart';
import 'package:auth_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Shortcuts to the theme extensions, so pages never hardcode tokens.
extension AppThemeContext on BuildContext {
  /// Brand colours without a `ColorScheme` slot.
  AppColors get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);
  }

  /// Monospace data styles.
  AppTextStyles get appText {
    final theme = Theme.of(this);
    return theme.extension<AppTextStyles>() ??
        AppTextStyles.withColor(theme.colorScheme.onSurface);
  }

  /// Spacing tokens.
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? const AppSpacing();
}
