import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';
import 'package:equatable/equatable.dart';

/// Immutable state of the sign-up form.
class SignUpState extends Equatable {
  /// Creates a state.
  const SignUpState({
    this.status = SubmitStatus.initial,
    this.failure,
    this.email,
  });

  /// Where the submit is in its lifecycle.
  final SubmitStatus status;

  /// Why the last submit failed (status `failure` only).
  final Failure? failure;

  /// Normalised address the confirmation email was sent to (status
  /// `success` only); the page passes it to Check Your Email.
  final String? email;

  @override
  List<Object?> get props => [status, failure, email];
}
