import 'package:auth_app/core/router/auth_redirect.dart';
import 'package:auth_app/core/router/routes.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:auth_app/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = AppUser(id: '1', email: 'a@b.co', emailConfirmed: true);
  const resolving = AuthSessionState();
  const signedOut = AuthSessionState(status: AuthSessionStatus.success);
  const signedIn = AuthSessionState(
    status: AuthSessionStatus.success,
    user: user,
  );

  group('resolving', () {
    test('any route goes to splash', () {
      expect(authRedirect(resolving, Routes.homePath), Routes.splashPath);
      expect(authRedirect(resolving, Routes.signInPath), Routes.splashPath);
    });
    test('splash stays', () {
      expect(authRedirect(resolving, Routes.splashPath), isNull);
    });
  });

  group('unauthenticated', () {
    test('splash and home go to sign in', () {
      expect(authRedirect(signedOut, Routes.splashPath), Routes.signInPath);
      expect(authRedirect(signedOut, Routes.homePath), Routes.signInPath);
      expect(authRedirect(signedOut, '/unknown'), Routes.signInPath);
    });
    test('auth routes are reachable', () {
      for (final path in Routes.publicPaths) {
        expect(authRedirect(signedOut, path), isNull);
      }
    });
    test('resolution failure behaves as signed out', () {
      const failed = AuthSessionState(status: AuthSessionStatus.failure);
      expect(authRedirect(failed, Routes.homePath), Routes.signInPath);
    });
  });

  group('authenticated', () {
    test('splash and auth routes go to home', () {
      expect(authRedirect(signedIn, Routes.splashPath), Routes.homePath);
      for (final path in Routes.publicPaths) {
        expect(authRedirect(signedIn, path), Routes.homePath);
      }
    });
    test('home stays, also while logging out', () {
      expect(authRedirect(signedIn, Routes.homePath), isNull);
      const loggingOut = AuthSessionState(
        status: AuthSessionStatus.loading,
        user: user,
      );
      expect(authRedirect(loggingOut, Routes.homePath), isNull);
    });
  });
}
