/// Outcome of opening an email confirmation link.
enum EmailLinkResult {
  /// The email is confirmed. Show Sign In with a success message.
  confirmed,

  /// The link is invalid, expired or already used. Show the expired variant
  /// of Check Your Email.
  invalid,
}
