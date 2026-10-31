import 'package:auth_app/core/utils/validators.dart';

/// Returns the current time; injectable so tests control the clock.
typedef NowProvider = DateTime Function();

/// Emits once per second while a cooldown countdown is shown.
typedef CooldownTicker = Stream<void> Function();

/// Default [CooldownTicker]: one event per second.
Stream<void> secondTicker() =>
    Stream<void>.periodic(const Duration(seconds: 1));

/// In-memory per-email cooldown for "Resend email" (AC-09, AC-10).
///
/// Lives for the app run only (registered as a singleton), so leaving and
/// re-entering Check Your Email keeps the countdown; a restart resets it.
class ResendCooldownStore {
  /// Creates the store. [now] defaults to the system clock.
  ResendCooldownStore([this._now = DateTime.now]);

  /// Length of the cooldown in seconds.
  static const int cooldownSeconds = 60;

  final NowProvider _now;
  final Map<String, DateTime> _availableAt = {};
  String? _lastEmail;

  /// The most recent address a confirmation email was sent to in this run.
  String? get lastEmail => _lastEmail;

  /// Starts a fresh [cooldownSeconds] cooldown for [email].
  void start(String email) {
    final key = Validators.normalizeEmail(email);
    _lastEmail = key;
    _availableAt[key] = _now().add(const Duration(seconds: cooldownSeconds));
  }

  /// Whole seconds left for [email] (rounded up), 0 when none.
  int remainingSeconds(String email) {
    final end = _availableAt[Validators.normalizeEmail(email)];
    if (end == null) return 0;
    final millis = end.difference(_now()).inMilliseconds;
    if (millis <= 0) return 0;
    return (millis / 1000).ceil();
  }
}
