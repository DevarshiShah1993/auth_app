part of 'auth_session_event.dart';

/// An email confirmation link was opened.
class AuthSessionLinkResultReceived extends AuthSessionEvent {
  /// Creates the event.
  const AuthSessionLinkResultReceived(this.result);

  /// What happened to the link.
  final EmailLinkResult result;

  @override
  List<Object?> get props => [result];
}
