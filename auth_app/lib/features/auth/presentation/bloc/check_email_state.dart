import 'package:auth_app/core/error/failure.dart';
import 'package:auth_app/features/auth/presentation/bloc/submit_status.dart';
import 'package:equatable/equatable.dart';

/// Immutable state of Check Your Email (resend + cooldown).
class CheckEmailState extends Equatable {
  /// Creates a state.
  const CheckEmailState({
    this.status = SubmitStatus.initial,
    this.failure,
    this.email,
    this.remainingSeconds = 0,
  });

  /// Resend request lifecycle.
  final SubmitStatus status;

  /// Why the last resend failed (status `failure` only).
  final Failure? failure;

  /// Pending address, or null when the user still has to type it.
  final String? email;

  /// Seconds until Resend is allowed again; 0 means allowed.
  final int remainingSeconds;

  /// Whether Resend is blocked by the cooldown.
  bool get isCoolingDown => remainingSeconds > 0;

  /// Copy with the given fields replaced. [failure] is always replaced (not
  /// kept) so a new status never carries a stale failure.
  CheckEmailState copyWith({
    SubmitStatus? status,
    Failure? failure,
    String? email,
    int? remainingSeconds,
  }) {
    return CheckEmailState(
      status: status ?? this.status,
      failure: failure,
      email: email ?? this.email,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  @override
  List<Object?> get props => [status, failure, email, remainingSeconds];
}
