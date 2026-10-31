import 'package:flutter/material.dart';

/// Spacing, radius and sizing tokens (8px grid, design-system.md 2.3).
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  /// Creates the standard spacing scale.
  const AppSpacing();

  /// Half step, icon gaps only.
  double get xs => 4;

  /// Small gap.
  double get sm => 8;

  /// Medium gap (default between fields).
  double get md => 16;

  /// Large gap.
  double get lg => 24;

  /// Extra large gap.
  double get xl => 32;

  /// Double extra large gap.
  double get xxl => 48;

  /// Corner radius used everywhere.
  double get radius => 6;

  /// Minimum height of buttons and fields (also the minimum hit target).
  double get controlHeight => 48;

  /// Page gutter on compact widths.
  double get gutter => 16;

  /// Page gutter when the width is at least [wideBreakpoint].
  double get gutterWide => 24;

  /// Width at which the wide gutter applies.
  double get wideBreakpoint => 600;

  /// Maximum width of the centered content column.
  double get maxContentWidth => 400;

  @override
  AppSpacing copyWith() => const AppSpacing();

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) => this;
}
