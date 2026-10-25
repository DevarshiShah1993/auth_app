/// Route names and paths. Navigate with `context.goNamed(Routes.signIn)`.
abstract final class Routes {
  /// Splash while the stored session resolves (also the initial location).
  static const String splash = 'splash';

  /// Splash path.
  static const String splashPath = '/';

  /// Sign In route name.
  static const String signIn = 'sign-in';

  /// Sign In path.
  static const String signInPath = '/sign-in';

  /// Sign Up route name.
  static const String signUp = 'sign-up';

  /// Sign Up path.
  static const String signUpPath = '/sign-up';

  /// Check Your Email route name (also the expired-link variant).
  static const String checkEmail = 'check-email';

  /// Check Your Email path.
  static const String checkEmailPath = '/check-email';

  /// Home route name.
  static const String home = 'home';

  /// Home path.
  static const String homePath = '/home';

  /// Routes an unauthenticated user may open.
  static const Set<String> publicPaths = {
    signInPath,
    signUpPath,
    checkEmailPath,
  };
}
