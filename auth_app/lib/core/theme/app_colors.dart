import 'package:flutter/material.dart';

/// Brand colour tokens that have no `ColorScheme` slot (design-system.md 2.1, 3).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Creates a colour token set.
  const AppColors({
    required this.primaryText,
    required this.success,
    required this.successContainer,
    required this.successText,
    required this.cardShadow,
    required this.disabledFill,
  });

  /// Links and text buttons (passes 4.5:1, unlike the brand fill colour).
  final Color primaryText;

  /// Success icon and border colour.
  final Color success;

  /// Success banner fill.
  final Color successContainer;

  /// Success text colour.
  final Color successText;

  /// Card shadow colour (transparent in dark mode).
  final Color cardShadow;

  /// Fill of disabled buttons and fields.
  final Color disabledFill;

  /// Light palette.
  static const AppColors light = AppColors(
    primaryText: Color(0xFFB45309),
    success: Color(0xFF10B981),
    successContainer: Color(0xFFECFDF5),
    successText: Color(0xFF047857),
    cardShadow: Color(0x0D000000),
    disabledFill: Color(0xFFE2E8F0),
  );

  /// Derived dark palette.
  static const AppColors dark = AppColors(
    primaryText: Color(0xFFFBBF24),
    success: Color(0xFF34D399),
    successContainer: Color(0xFF0B2F24),
    successText: Color(0xFF6EE7B7),
    cardShadow: Color(0x00000000),
    disabledFill: Color(0xFF1E293B),
  );

  @override
  AppColors copyWith({
    Color? primaryText,
    Color? success,
    Color? successContainer,
    Color? successText,
    Color? cardShadow,
    Color? disabledFill,
  }) {
    return AppColors(
      primaryText: primaryText ?? this.primaryText,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      successText: successText ?? this.successText,
      cardShadow: cardShadow ?? this.cardShadow,
      disabledFill: disabledFill ?? this.disabledFill,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      success: Color.lerp(success, other.success, t) ?? success,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      successText: Color.lerp(successText, other.successText, t) ?? successText,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t) ?? cardShadow,
      disabledFill:
          Color.lerp(disabledFill, other.disabledFill, t) ?? disabledFill,
    );
  }
}
