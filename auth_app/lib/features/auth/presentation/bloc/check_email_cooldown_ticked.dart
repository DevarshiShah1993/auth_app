part of 'check_email_event.dart';

/// One second of the cooldown passed; recompute the remaining time.
class CheckEmailCooldownTicked extends CheckEmailEvent {
  /// Creates the event.
  const CheckEmailCooldownTicked();
}
