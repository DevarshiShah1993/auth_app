/// App-wide constants that are not secrets.
abstract final class AppConstants {
  /// Deep link Supabase redirects to after email confirmation. Must also be
  /// listed under Authentication -> URL Configuration -> Redirect URLs.
  static const String authRedirectUrl = 'io.supabase.authapp://login-callback/';
}
