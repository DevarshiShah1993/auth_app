import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';

/// Pure redirect rules for the auth guard.
///
/// Returns the location to redirect to, or null to stay on [location].
String? authRedirect(AuthSessionState state, String location) {
  if (state.isResolving) {
    return location == Routes.splashPath ? null : Routes.splashPath;
  }
  final isPublic = Routes.publicPaths.contains(location);
  if (state.isAuthenticated) {
    return isPublic || location == Routes.splashPath ? Routes.homePath : null;
  }
  return isPublic ? null : Routes.signInPath;
}
