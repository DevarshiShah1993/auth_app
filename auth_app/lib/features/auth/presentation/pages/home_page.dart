import 'package:auth_app/core/theme/app_motion.dart';
import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/widgets/home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home: app bar with hamburger, drawer with "Log out", centered email
/// (AC-25, AC-25a, AC-25b, AC-26).
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Bakery ERP'),
      ),
      drawer: const HomeDrawer(),
      body: BlocListener<AuthSessionBloc, AuthSessionState>(
        // Close the drawer once a logout has finished (AC-26).
        listenWhen: (previous, current) =>
            previous.status == AuthSessionStatus.loading &&
            current.status != AuthSessionStatus.loading,
        listener: (context, state) => Scaffold.maybeOf(context)?.closeDrawer(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.gutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: spacing.maxContentWidth),
              child: BlocSelector<AuthSessionBloc, AuthSessionState, String>(
                selector: (state) => state.user?.email ?? '',
                builder: (context, email) {
                  Widget text = Semantics(
                    label: 'Signed in as $email',
                    excludeSemantics: true,
                    child: Text(
                      email,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: context.appText.dataLarge,
                    ),
                  );
                  if (!AppMotion.reduced(context)) {
                    text = text.animate().fadeIn(duration: AppMotion.pageIn);
                  }
                  return text;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
