import 'package:equatable/equatable.dart';

/// The signed-in user as seen by the app. Pure Dart, backend-agnostic.
class AppUser extends Equatable {
  /// Creates a user.
  const AppUser({
    required this.id,
    required this.email,
    required this.emailConfirmed,
  });

  /// Unique user id.
  final String id;

  /// Email address (lower-cased by the backend), empty if unknown.
  final String email;

  /// Whether the email address has been confirmed.
  final bool emailConfirmed;

  @override
  List<Object?> get props => [id, email, emailConfirmed];
}
