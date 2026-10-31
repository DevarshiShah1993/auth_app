import 'package:equatable/equatable.dart';

/// Email and password input for sign-up and sign-in use cases.
class EmailPasswordParams extends Equatable {
  /// Creates the params.
  const EmailPasswordParams({required this.email, required this.password});

  /// Email address.
  final String email;

  /// Password (never logged).
  final String password;

  @override
  List<Object?> get props => [email, password];
}
