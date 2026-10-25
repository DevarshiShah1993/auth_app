import 'package:auth_app/features/auth/data/models/auth_state_event_model.dart';
import 'package:auth_app/features/auth/data/models/user_model.dart';

/// Talks to the auth backend. Throws backend exceptions; the repository
/// converts them to `Failure`.
abstract class AuthRemoteDataSource {
  /// Creates the account and sends the confirmation email.
  Future<void> signUp({required String email, required String password});

  /// Signs in with email and password.
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  });

  /// Re-sends the sign-up confirmation email.
  Future<void> resendConfirmation({required String email});

  /// Clears the local session and revokes it on the server.
  Future<void> signOut();

  /// User of the stored session, if any.
  UserModel? get currentUser;

  /// Auth state changes. Stream errors are delivered as error events.
  Stream<AuthStateEventModel> get authStateChanges;
}
