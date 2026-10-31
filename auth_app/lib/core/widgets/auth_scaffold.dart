import 'package:auth_app/core/theme/app_motion.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Layout wrapper for auth screens: safe area, scrolling, keyboard handling,
/// responsive gutters and a 400dp centered column with a page-in animation.
class AuthScaffold extends StatelessWidget {
  /// Creates the scaffold around [child].
  const AuthScaffold({required this.child, super.key});

  /// Page content (usually the form card).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final media = MediaQuery.of(context);
    final gutter = media.size.width >= spacing.wideBreakpoint
        ? spacing.gutterWide
        : spacing.gutter;
    final keyboardOpen = media.viewInsets.bottom > 0;

    Widget content = child;
    if (!AppMotion.reduced(context)) {
      content = content
          .animate()
          .fadeIn(duration: AppMotion.pageIn)
          .slideY(
            begin: 0.04,
            end: 0,
            duration: AppMotion.pageIn,
            curve: AppMotion.curve,
          );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final verticalPadding = spacing.md;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: gutter,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - verticalPadding * 2,
                ),
                child: Align(
                  alignment: keyboardOpen
                      ? Alignment.topCenter
                      : Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: keyboardOpen ? spacing.lg - verticalPadding : 0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: spacing.maxContentWidth,
                      ),
                      child: content,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
