import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Surface card that holds an auth form: hairline border, radius, soft
/// shadow, 24dp padding (16dp on narrow screens).
class AuthCard extends StatelessWidget {
  /// Creates the card around [child].
  const AuthCard({required this.child, super.key});

  /// Card content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final narrow = MediaQuery.sizeOf(context).width <= 360;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(spacing.radius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(narrow ? spacing.md : spacing.lg),
        child: child,
      ),
    );
  }
}
