/// Backend-agnostic kind of auth state change.
enum AuthEventType {
  /// Stored session resolved on startup.
  initialSession,

  /// A session was created (password sign-in or email link).
  signedIn,

  /// The session ended.
  signedOut,

  /// The access token was refreshed.
  tokenRefreshed,

  /// The user object changed.
  userUpdated,

  /// Any other event.
  other,

  /// The auth stream reported an error (for example an invalid link).
  error,
}
