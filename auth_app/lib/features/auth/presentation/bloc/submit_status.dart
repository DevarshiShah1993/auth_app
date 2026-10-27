/// Status of a form-style bloc (sign up, resend, ...).
enum SubmitStatus {
  /// Nothing submitted yet, or the last message was dismissed.
  initial,

  /// A request is in flight.
  loading,

  /// The last request succeeded.
  success,

  /// The last request failed; see the state's failure.
  failure,
}
