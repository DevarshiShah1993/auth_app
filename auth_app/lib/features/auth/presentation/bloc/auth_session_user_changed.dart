part of 'auth_session_event.dart';

/// The auth state stream emitted a user, or `null` when signed out.
class AuthSessionUserChanged extends AuthSessionEvent {
  /// Creates the event.
  const AuthSessionUserChanged(this.user);

  /// The signed-in user, or null.
  final AppUser? user;

  @override
  List<Object?> get props => [user];
}
