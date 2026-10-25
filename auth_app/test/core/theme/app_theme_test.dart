import 'package:auth_app/core/theme/app_colors.dart';
import 'package:auth_app/core/theme/app_spacing.dart';
import 'package:auth_app/core/theme/app_text_styles.dart';
import 'package:auth_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme matches design tokens', () {
    final t = AppTheme.light;
    expect(t.brightness, Brightness.light);
    expect(t.colorScheme.primary, const Color(0xFFD97706));
    expect(t.colorScheme.onPrimary, const Color(0xFF0F172A));
    expect(t.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
    expect(t.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(t.extension<AppColors>()?.primaryText, const Color(0xFFB45309));
    expect(t.extension<AppSpacing>()?.radius, 6);
    expect(
      t.extension<AppTextStyles>()?.dataSmall.fontFamily,
      'JetBrains Mono',
    );
    expect(t.textTheme.headlineMedium?.fontFamily, 'Inter');
  });

  test('dark theme uses derived palette', () {
    final t = AppTheme.dark;
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme.primary, const Color(0xFFF59E0B));
    expect(t.scaffoldBackgroundColor, const Color(0xFF0B1220));
    expect(t.colorScheme.surface, const Color(0xFF111A2B));
    expect(t.extension<AppColors>()?.successText, const Color(0xFF6EE7B7));
  });
}
