import 'package:auth_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Plays one horizontal shake (320 ms) when first built, unless the platform
/// asks for reduced motion. Used on failure banners.
class Shaking extends StatelessWidget {
  /// Creates the wrapper.
  const Shaking({required this.child, super.key});

  /// Widget to shake.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return child.animate().shake(
      duration: AppMotion.shake,
      hz: 4,
      offset: const Offset(6, 0),
      rotation: 0,
    );
  }
}
