import 'package:flutter/material.dart';

/// Motion tokens (design-system.md section 4). Every effect is under 400 ms.
abstract final class AppMotion {
  /// Default curve for all effects.
  static const Curve curve = Curves.easeOutCubic;

  /// Page content fade + slide-in.
  static const Duration pageIn = Duration(milliseconds: 300);

  /// Per-child stagger effect duration.
  static const Duration staggerIn = Duration(milliseconds: 200);

  /// Delay step between staggered children.
  static const Duration staggerStep = Duration(milliseconds: 40);

  /// Validation shake.
  static const Duration shake = Duration(milliseconds: 320);

  /// Error text / banner entrance.
  static const Duration errorIn = Duration(milliseconds: 200);

  /// Button label to spinner swap.
  static const Duration buttonLoading = Duration(milliseconds: 200);

  /// Success icon scale + fade.
  static const Duration successIn = Duration(milliseconds: 300);

  /// Whether effects must be skipped (platform reduce-motion setting).
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
