part of 'check_email_event.dart';

/// The user tapped "Resend email". Ignored while a request runs, during the
/// cooldown, or when [email] is not valid (no network call, AC-13c).
class CheckEmailResendRequested extends CheckEmailEvent {
  /// Creates the event.
  const CheckEmailResendRequested({required this.email});

  /// Address typed in the field, or the known pending address.
  final String email;

  @override
  List<Object?> get props => [email];
}
