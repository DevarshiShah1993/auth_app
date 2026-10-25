part of 'sign_in_event.dart';

/// The user submitted a valid sign-in form.
class SignInSubmitted extends SignInEvent {
  /// Creates the event.
  const SignInSubmitted({required this.email, required this.password});

  /// Email as typed (the bloc trims and lower-cases it).
  final String email;

  /// Password (never logged).
  final String password;

  @override
  List<Object?> get props => [email, password];
}
