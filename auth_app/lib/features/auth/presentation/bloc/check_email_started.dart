part of 'check_email_event.dart';

/// The page opened. [email] is the address from sign-up or Sign In, or null
/// (the bloc then falls back to the last address used in this app run).
class CheckEmailStarted extends CheckEmailEvent {
  /// Creates the event.
  const CheckEmailStarted({this.email});

  /// Pending address, if known.
  final String? email;

  @override
  List<Object?> get props => [email];
}
