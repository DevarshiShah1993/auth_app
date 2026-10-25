import 'package:auth_app/core/router/auth_redirect.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:auth_app/features/auth/presentation/pages/check_email_page.dart';
import 'package:auth_app/features/auth/presentation/pages/home_page.dart';
import 'package:auth_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:auth_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:auth_app/features/auth/presentation/pages/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Builds the app router. Redirects are driven by [sessionBloc] through
/// [refreshListenable] (the caller owns and disposes it).
///
/// An email-link outcome (AC-12, AC-13) sends the signed-out user once to
/// Sign In (confirmed) or to Check Your Email (invalid link). The result
/// stays in the bloc state for the pages until they consume it.
GoRouter createRouter({
  required AuthSessionBloc sessionBloc,
  required Listenable refreshListenable,
}) {
  EmailLinkResult? handledLink;

  String? redirect(AuthSessionState state, String location) {
    final link = state.linkResult;
    if (link == null) {
      handledLink = null;
    } else if (!state.isResolving &&
        !state.isAuthenticated &&
        link != handledLink) {
      handledLink = link;
      return link == EmailLinkResult.confirmed
          ? Routes.signInPath
          : Routes.checkEmailPath;
    }
    return authRedirect(state, location);
  }

  return GoRouter(
    initialLocation: Routes.splashPath,
    refreshListenable: refreshListenable,
    redirect: (context, routerState) =>
        redirect(sessionBloc.state, routerState.uri.path),
    routes: [
      GoRoute(
        name: Routes.splash,
        path: Routes.splashPath,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        name: Routes.signIn,
        path: Routes.signInPath,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        name: Routes.signUp,
        path: Routes.signUpPath,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        name: Routes.checkEmail,
        path: Routes.checkEmailPath,
        builder: (context, state) => const CheckEmailPage(),
      ),
      GoRoute(
        name: Routes.home,
        path: Routes.homePath,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
