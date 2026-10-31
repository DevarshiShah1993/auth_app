import 'package:auth_app/core/theme/app_colors.dart';
import 'package:auth_app/core/theme/app_spacing.dart';
import 'package:auth_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// The single source of `ThemeData` for the app (light and dark).
abstract final class AppTheme {
  /// Light theme.
  static final ThemeData light = _build(
    scheme: _lightScheme,
    extras: AppColors.light,
    scaffold: const Color(0xFFF8FAFC),
    inputIdle: const Color(0xFF64748B),
    scrimOpacity: 0.4,
  );

  /// Derived dark theme.
  static final ThemeData dark = _build(
    scheme: _darkScheme,
    extras: AppColors.dark,
    scaffold: const Color(0xFF0B1220),
    inputIdle: const Color(0xFF7B8BA3),
    scrimOpacity: 0.6,
  );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFD97706),
    onPrimary: Color(0xFF0F172A),
    primaryContainer: Color(0xFFFEF3C7),
    onPrimaryContainer: Color(0xFF78350F),
    secondary: Color(0xFF475569),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2E8F0),
    onSecondaryContainer: Color(0xFF0F172A),
    tertiary: Color(0xFF475569),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE2E8F0),
    onTertiaryContainer: Color(0xFF0F172A),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEF2F2),
    onErrorContainer: Color(0xFFB91C1C),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF0F172A),
    inverseSurface: Color(0xFF0F172A),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFFF59E0B),
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFF1F5F9),
    surfaceDim: Color(0xFFF1F5F9),
    surfaceBright: Color(0xFFFFFFFF),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF59E0B),
    onPrimary: Color(0xFF0F172A),
    primaryContainer: Color(0xFF451A03),
    onPrimaryContainer: Color(0xFFFDE68A),
    secondary: Color(0xFF94A3B8),
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: Color(0xFF263449),
    onSecondaryContainer: Color(0xFFF1F5F9),
    tertiary: Color(0xFF94A3B8),
    onTertiary: Color(0xFF0F172A),
    tertiaryContainer: Color(0xFF263449),
    onTertiaryContainer: Color(0xFFF1F5F9),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF3F1212),
    onErrorContainer: Color(0xFFFCA5A5),
    surface: Color(0xFF111A2B),
    onSurface: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFFA8B5C7),
    outline: Color(0xFF7B8BA3),
    outlineVariant: Color(0xFF263449),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF1F5F9),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: Color(0xFFD97706),
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Color(0xFF0B1220),
    surfaceContainerLow: Color(0xFF0B1220),
    surfaceContainer: Color(0xFF111A2B),
    surfaceContainerHigh: Color(0xFF162033),
    surfaceContainerHighest: Color(0xFF1E293B),
    surfaceDim: Color(0xFF0B1220),
    surfaceBright: Color(0xFF162033),
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppColors extras,
    required Color scaffold,
    required Color inputIdle,
    required double scrimOpacity,
  }) {
    const spacing = AppSpacing();
    final radius = BorderRadius.circular(spacing.radius);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final textTheme = AppTextStyles.textTheme(scheme.onSurface);
    final labelLarge = textTheme.labelLarge;
    final hairline = BorderSide(color: scheme.outlineVariant);
    final fullWidth = Size(double.infinity, spacing.controlHeight);
    final disabledFg = scheme.onSurface.withValues(alpha: 0.6);

    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );

    final focusRing = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: scheme.primary, width: 2);
      }
      return null;
    });

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: scaffold,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      highlightColor: scheme.primary.withValues(alpha: 0.12),
      extensions: [extras, AppTextStyles.withColor(scheme.onSurface), spacing],
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        toolbarHeight: 56,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
        shape: Border(bottom: hairline),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrimColor: scheme.scrim.withValues(alpha: scrimOpacity),
        width: 304,
        shape: Border(right: hairline),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 8,
        minTileHeight: spacing.controlHeight,
        shape: shape,
        selectedTileColor: scheme.primaryContainer,
        iconColor: scheme.secondary,
        textColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: outline(inputIdle, 1),
        enabledBorder: outline(inputIdle, 1),
        focusedBorder: outline(scheme.primary, 2),
        errorBorder: outline(scheme.error, 1),
        focusedErrorBorder: outline(scheme.error, 2),
        disabledBorder: outline(scheme.outlineVariant, 1),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          final base = textTheme.labelMedium ?? const TextStyle();
          if (states.contains(WidgetState.error)) {
            return base.copyWith(color: scheme.onErrorContainer);
          }
          if (states.contains(WidgetState.focused)) {
            return base.copyWith(color: extras.primaryText);
          }
          return base.copyWith(color: scheme.onSurfaceVariant);
        }),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        helperStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onErrorContainer,
        ),
        errorMaxLines: 3,
        prefixIconColor: scheme.secondary,
        suffixIconColor: scheme.secondary,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(fullWidth),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? extras.disabledFill
                : scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onPrimary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.onPrimary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.focused)) {
              return scheme.onPrimary.withValues(alpha: 0.16);
            }
            return null;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: scheme.onSurface, width: 2);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(fullWidth),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? extras.disabledFill
                : null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? disabledFg
                : scheme.onSurface;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: scheme.primary, width: 2);
            }
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: scheme.outlineVariant);
            }
            return BorderSide(color: inputIdle);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, spacing.controlHeight)),
          tapTargetSize: MaterialTapTargetSize.padded,
          elevation: const WidgetStatePropertyAll(0),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(labelLarge),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : extras.primaryText;
          }),
          side: focusRing,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          iconSize: const WidgetStatePropertyAll(24),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          side: focusRing,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius, side: hairline),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        elevation: 0,
        shape: shape,
        insetPadding: const EdgeInsets.all(16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: Colors.transparent,
      ),
    );
  }
}
