import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/domain/entities/app_user.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for authentication operations.
///
/// Session policy (requirements OQ-01): a session that appears because the
/// user tapped the email confirmation link is NOT a signed-in session. The
/// implementation signs it out locally, so [authStateChanges] emits `null`
/// for it, and reports the link outcome on [emailLinkResults] instead
/// (`Right` = email confirmed, `Left` = invalid/expired link). The UI then
/// sends the user to Sign In. Only sessions created by [signInWithPassword],
/// restored on launch or refreshed count as signed in.
abstract class AuthRepository {
  /// Registers a new account and triggers the confirmation email. Success
  /// means "email sent"; no session is created.
  Future<Either<Failure, Unit>> signUp({
    required String email,
    required String password,
  });

  /// Signs in with email and password.
  Future<Either<Failure, AppUser>> signInWithPassword({
    required String email,
    required String password,
  });

  /// Re-sends the sign-up confirmation email.
  Future<Either<Failure, Unit>> resendConfirmation({required String email});

  /// Signs out. The local session is cleared even when this returns a
  /// `Left` (for example when offline), see requirement AC-26.
  Future<Either<Failure, Unit>> signOut();

  /// The user of the currently stored session, or `null`.
  AppUser? get currentUser;

  /// Emits the current user (or `null` when signed out) on every auth change.
  /// Listen to this before [emailLinkResults] (they share one upstream).
  Stream<AppUser?> get authStateChanges;

  /// Outcomes of opening an email confirmation link, see class docs.
  Stream<Either<Failure, Unit>> get emailLinkResults;
}
