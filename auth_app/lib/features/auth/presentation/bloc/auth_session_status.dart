/// Lifecycle of the session state.
enum AuthSessionStatus {
  /// The stored session has not been resolved yet (splash is shown).
  initial,

  /// A logout is in progress. The user is still signed in.
  loading,

  /// The session is resolved. `user == null` means signed out.
  success,

  /// Resolving the session failed. Treated as signed out.
  failure,
}
