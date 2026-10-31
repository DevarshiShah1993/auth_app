import 'package:equatable/equatable.dart';

part 'check_email_cooldown_ticked.dart';
part 'check_email_message_dismissed.dart';
part 'check_email_resend_requested.dart';
part 'check_email_started.dart';

/// Base class of all [CheckEmailBloc] events.
sealed class CheckEmailEvent extends Equatable {
  /// Creates an event.
  const CheckEmailEvent();

  @override
  List<Object?> get props => [];
}
