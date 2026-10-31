import 'package:equatable/equatable.dart';

part 'sign_in_failure_dismissed.dart';
part 'sign_in_submitted.dart';

/// Base class of all [SignInBloc] events.
sealed class SignInEvent extends Equatable {
  /// Creates an event.
  const SignInEvent();

  @override
  List<Object?> get props => [];
}
