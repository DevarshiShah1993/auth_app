import 'package:auth_app/core/theme/theme_context_extension.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home drawer: app name, signed-in email and the "Log out" item, which is
/// the only item (AC-25b). Shows a spinner on the tile while logging out.
class HomeDrawer extends StatelessWidget {
  /// Creates the drawer.
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final scheme = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: BlocBuilder<AuthSessionBloc, AuthSessionState>(
          builder: (context, state) {
            final loggingOut = state.status == AuthSessionStatus.loading;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bakery', style: theme.textTheme.titleMedium),
                      SizedBox(height: spacing.xs),
                      Text(
                        state.user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appText.dataSmall.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.sm,
                  ),
                  child: ListTile(
                    enabled: !loggingOut,
                    leading: loggingOut
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.secondary,
                            ),
                          )
                        : const Icon(Icons.logout),
                    title: Text('Log out', style: theme.textTheme.bodyLarge),
                    onTap: () => context.read<AuthSessionBloc>().add(
                      const AuthSessionLogoutRequested(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
