import 'package:equatable/equatable.dart';

part 'sign_up_failure_dismissed.dart';
part 'sign_up_submitted.dart';

/// Base class of all [SignUpBloc] events.
sealed class SignUpEvent extends Equatable {
  /// Creates an event.
  const SignUpEvent();

  @override
  List<Object?> get props => [];
}
