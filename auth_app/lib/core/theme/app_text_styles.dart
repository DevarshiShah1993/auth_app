import 'package:flutter/material.dart';

/// Monospace data styles plus the Inter [TextTheme] builder
/// (design-system.md 2.2).
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  /// Creates the data styles.
  const AppTextStyles({required this.dataLarge, required this.dataSmall});

  /// Builds the data styles in [color].
  factory AppTextStyles.withColor(Color color) {
    return AppTextStyles(
      dataLarge: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 24 / 16,
        color: color,
      ),
      dataSmall: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 20 / 14,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  /// JetBrains Mono Medium 16/24, e.g. the Home email.
  final TextStyle dataLarge;

  /// JetBrains Mono Regular 14/20 tabular, e.g. countdown and target email.
  final TextStyle dataSmall;

  /// Builds the Inter [TextTheme] in [color].
  static TextTheme textTheme(Color color) {
    TextStyle inter(
      FontWeight weight,
      double size,
      double lineHeight,
      double tracking,
    ) {
      return TextStyle(
        fontFamily: 'Inter',
        fontWeight: weight,
        fontSize: size,
        height: lineHeight / size,
        letterSpacing: tracking,
        color: color,
      );
    }

    return TextTheme(
      headlineMedium: inter(FontWeight.w600, 28, 36, -0.56),
      titleLarge: inter(FontWeight.w600, 22, 28, -0.44),
      titleMedium: inter(FontWeight.w600, 16, 24, 0),
      bodyLarge: inter(FontWeight.w400, 16, 24, 0),
      bodyMedium: inter(FontWeight.w400, 14, 20, 0),
      bodySmall: inter(FontWeight.w400, 12, 16, 0.12),
      labelLarge: inter(FontWeight.w600, 14, 20, 0.14),
      labelMedium: inter(FontWeight.w500, 12, 16, 0.24),
    );
  }

  @override
  AppTextStyles copyWith({TextStyle? dataLarge, TextStyle? dataSmall}) {
    return AppTextStyles(
      dataLarge: dataLarge ?? this.dataLarge,
      dataSmall: dataSmall ?? this.dataSmall,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      dataLarge: TextStyle.lerp(dataLarge, other.dataLarge, t) ?? dataLarge,
      dataSmall: TextStyle.lerp(dataSmall, other.dataSmall, t) ?? dataSmall,
    );
  }
}
