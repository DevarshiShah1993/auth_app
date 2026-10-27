part of 'sign_up_event.dart';

/// The user submitted a valid sign-up form.
class SignUpSubmitted extends SignUpEvent {
  /// Creates the event.
  const SignUpSubmitted({required this.email, required this.password});

  /// Email as typed (the bloc trims and lower-cases it).
  final String email;

  /// Password (never logged).
  final String password;

  @override
  List<Object?> get props => [email, password];
}
