import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';
import 'package:equatable/equatable.dart';

/// Immutable state of the sign-in form.
class SignInState extends Equatable {
  /// Creates a state.
  const SignInState({this.status = SubmitStatus.initial, this.failure});

  /// Where the submit is in its lifecycle. `success` means the session was
  /// created; the router then moves the user to Home.
  final SubmitStatus status;

  /// Why the last submit failed (status `failure` only).
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}
