import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Rounded tile with a centered icon used at the top of auth cards.
/// The [isError] variant uses the error container colours.
class AuthIconTile extends StatelessWidget {
  /// Creates the tile.
  const AuthIconTile({
    required this.icon,
    super.key,
    this.size = 48,
    this.isError = false,
  });

  /// Icon to show.
  final IconData icon;

  /// Tile edge length; the icon is about half of it.
  final double size;

  /// Whether to use error colours.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isError ? scheme.errorContainer : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(context.spacing.radius),
        ),
        child: Icon(
          icon,
          size: size / 2,
          color: isError
              ? scheme.onErrorContainer
              : context.appColors.primaryText,
        ),
      ),
    );
  }
}
