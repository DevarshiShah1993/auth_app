import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder router; later tasks add routes and the auth redirect.
GoRouter createRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Bakery'))),
      ),
    ],
  );
}
