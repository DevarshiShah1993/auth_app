import 'package:auth_app/core/router/app_router.dart';
import 'package:auth_app/core/router/stream_refresh_listenable.dart';
import 'package:auth_app/core/theme/app_theme.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root widget of the Bakery app.
///
/// Owns the single [AuthSessionBloc] for the app lifetime: it provides it to
/// the tree, feeds the router and closes it on dispose.
class App extends StatefulWidget {
  /// Creates the app around the already created [sessionBloc].
  const App({required this.sessionBloc, super.key});

  /// The app-wide session bloc (started by the caller).
  final AuthSessionBloc sessionBloc;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final StreamRefreshListenable _refresh = StreamRefreshListenable(
    widget.sessionBloc.stream,
  );
  late final GoRouter _router = createRouter(
    sessionBloc: widget.sessionBloc,
    refreshListenable: _refresh,
  );

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    // ignore: discarded_futures
    widget.sessionBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthSessionBloc>.value(
      value: widget.sessionBloc,
      child: MaterialApp.router(
        title: 'Bakery',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
