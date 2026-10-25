# Sprint 01 Requirements: Email Auth, Confirmation Link, Session Handling

_Owner of this file: BA. Task: T-01. Status: Approved by Owner (Gate 1), 2026-10-23. Open questions answered by Owner 2026-10-21. Sources: `docs/vision.md`, `CLAUDE.md`, `docs/sprints/sprint-01/plan.md`._

## 1. Scope

In scope:
- Email + password sign-up followed by an email confirmation link (no email OTP).
- "Check your email" screen with resend-confirmation (60 s cooldown).
- Email + password sign-in (only possible after the link is tapped).
- Session handling: auto-login on launch, auth-guarded routes, logout.

Deferred (not this sprint): phone sign-up/sign-in and the stub OTP step, forgot password, change password, phone password reset, social login, biometrics, profile editing.

## 2. User stories

- US-01: As a new user, I want to sign up with email and password so that I can have an account.
- US-02: As a new user, I want a confirmation link emailed to me so that I can prove I own the address.
- US-03: As a new user, I want to resend the confirmation email so that I can recover if it did not arrive.
- US-04: As a registered user, I want to sign in with email and password so that I can access the app.
- US-05: As a returning user, I want to stay signed in across app launches so that I do not log in every time.
- US-06: As a signed-in user, I want to log out so that my session ends on this device.
- US-07: As a signed-out user, I must not reach protected screens so that my data stays private.

## 3. Screens

Sign Up, Check Your Email, Sign In, Home (app bar titled "Bakery ERP" with hamburger menu, drawer containing Logout, centered user email). Splash/loading while the session is resolved on launch.

## 4. Validation rules (client-side; server errors are the source of truth)

| Field | Rule | Message |
|---|---|---|
| Email | Required; trimmed; valid email format (`local@domain.tld`) | "Enter a valid email address" |
| Password (sign-up) | Required; min 8 characters; at least 1 letter and 1 number | "Password must be at least 8 characters and include a letter and a number" |
| Confirm password (sign-up) | Must equal password | "Passwords do not match" |
| Password (sign-in) | Required only (no strength check, so legacy passwords are never blocked client-side) | "Enter your password" |

- Email is trimmed and compared case-insensitively; stored/sent lower-cased.
- Validation runs on submit and on field blur; errors clear when the user edits the field. Invalid forms do not call the backend.

## 5. Acceptance criteria

### Sign up
- AC-01: Sign Up shows email, password, confirm password fields, a "Sign up" button, and a link to Sign In.
- AC-02: Submitting invalid input shows the field-level messages from section 4 and makes no network call.
- AC-03: Valid submit calls Supabase `signUp(email, password, emailRedirectTo: <app deep link>)`; the button shows a loading state and fields are disabled until the response arrives.
- AC-04: On success the app navigates to Check Your Email, displaying the address the link was sent to. No session is created and the user is not taken to Home.
- AC-05: If the email is already registered, an error is shown on Sign Up (see section 6) and the user stays on the screen. (Note: Supabase may return a fake success for already-confirmed emails when enumeration protection is on; see OQ-02.)
- AC-06: The password is never shown in plain text unless the user toggles visibility; the toggle resets to hidden when the screen is left.

### Check your email and resend
- AC-07: Check Your Email shows the target address, instructions to tap the link, a "Resend email" button, and a "Back to sign in" action.
- AC-08: "Resend email" calls Supabase `resend(type: signup, email)`. On success a confirmation message is shown ("Confirmation email sent").
- AC-09: After sign-up lands on this screen, and after each successful resend, the Resend button is disabled for 60 seconds with a visible countdown. The first 60 s starts when the sign-up succeeds.
- AC-10: The cooldown is held in memory; leaving and re-entering the screen in the same app run does not reset it for the same email. Restarting the app resets it.
- AC-11: Resend failures (rate limit, network) show the matching message from section 6 and do not restart the cooldown unless the server accepted the request.
- AC-12: Tapping the confirmation link on the device opens the app via the configured deep link, the account becomes confirmed, and the user is shown a success message and taken to Sign In (see OQ-03 for auto-login alternative). The user is not auto-signed-in unless the Owner decides otherwise.
- AC-13: A user who opens an expired or already used link sees a clear error ("This link is invalid or has expired") on the `/check-email` expired-link variant, with a way to resend and a way back to Sign In. (Owner decision 2026-10-23)
  - AC-13a: If the pending email is known (same app run), the variant shows that email and a Resend button, subject to the cooldown (AC-09/AC-10).
  - AC-13b: If the app is opened from an expired link on a cold start and the pending email is unknown, the variant shows an email field plus a Resend button.
  - AC-13c: The email field uses the same validation and messages as the Sign In email (section 4); an invalid value shows the message and makes no network call.
  - AC-13d: Resend calls `resend(type: signup, email)`; on success it shows "Confirmation email sent" and the 60 s cooldown starts (button disabled with countdown). Failures use the section 6 messages.
  - AC-13e: A "Back to sign in" action is always visible on this variant and navigates to `/sign-in`.
  - AC-13f: The variant is reachable while unauthenticated only, consistent with AC-23/AC-24.
- Note (Owner decision 2026-10-23, not a requirement): Sign In email is prefilled after the link is tapped only if the link carries the email; otherwise the field is empty. No "You were signed out" banner is required.
- Naming (Owner decision 2026-10-23): the app display name is "Bakery".

### Sign in
- AC-14: Sign In shows email, password fields, a "Sign in" button, and a link to Sign Up. (Forgot-password link is not shown this sprint.)
- AC-15: Invalid input shows field-level messages from section 4 and makes no network call.
- AC-16: Valid submit calls `signInWithPassword(email, password)` with loading state and disabled fields.
- AC-17: On success the user is taken to Home and cannot navigate back to Sign In with the back button.
- AC-18: Wrong email or password shows one generic error ("Incorrect email or password") that does not reveal which was wrong. The password field is cleared; the email is kept.
- AC-19: Signing in with an unconfirmed email shows "Please confirm your email before signing in" with a "Resend confirmation email" action. The action navigates to Check Your Email for that address (respecting the cooldown, AC-09/AC-10), and no session exists.
- AC-20: Error banners/messages are dismissed when the user edits any field or resubmits.

### Session handling and routing
- AC-21: On launch, a splash/loading state is shown while the stored session is resolved; there is no flash of Sign In for a user with a valid session.
- AC-22: With a valid stored session the app opens Home directly (auto-login). With no session, or an invalid/expired session that cannot be refreshed, it opens Sign In.
- AC-23: Unauthenticated users can reach only `/sign-in`, `/sign-up`, and `/check-email`. Any other route (including deep links to Home) redirects to `/sign-in`.
- AC-24: Authenticated users who navigate to `/sign-in`, `/sign-up`, or `/check-email` are redirected to Home.
- AC-25: Home has a top app bar titled "Bakery ERP" (Owner decision 2026-10-23) with a hamburger (menu) icon on the left (leading position). The body contains a single widget, the signed-in user's email address, centered horizontally and vertically. Home shows no other body content and no standalone "Log out" button.
- AC-25a: Tapping the hamburger icon opens a drawer/menu (it may also open by edge swipe); tapping outside or the back action closes it.
- AC-25b: The drawer contains a "Log out" item; Logout is available only inside the drawer.
- AC-26: Selecting "Log out" in the drawer closes the drawer and calls `signOut()`, clears the local session, and navigates to Sign In; the back button cannot return to Home. If the network call fails the local session is still cleared and the user is signed out locally.
- AC-27: When the session ends elsewhere or the refresh token fails (auth state changes to signed out), the app redirects to Sign In within the same run without a restart.
- AC-28: Redirects are driven by `AuthSessionBloc` state, which listens to the repository's auth-state stream.

### States (per screen)
- AC-29: Every screen implements: initial, loading (submit in progress, button spinner, inputs disabled, no double submit), failure (message displayed, inputs re-enabled), and success (navigation or confirmation message) as in section 7.
- AC-30: All screens are usable on a small phone (360x640 logical px) with the keyboard open (content scrolls, submit button reachable) and in light and dark themes.

### Security
- AC-31: No log, crash report, analytics call, or error message contains a password, token, or the full session object.
- AC-32: Config is read from the git-ignored `.env` (`PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_PUBLISHABLE_KEY`); `.env.example` with empty values is committed; no key appears in source control. The app fails fast with a clear developer error if either value is missing.
- AC-33: Only the publishable key is used in the client. A service-role key is never present in the repo or app.

## 6. Error mapping

| Situation | Supabase signal | User message | Where |
|---|---|---|---|
| Wrong email or password | `AuthException` code `invalid_credentials` (HTTP 400) | "Incorrect email or password" | Sign In |
| Email not confirmed | code `email_not_confirmed` | "Please confirm your email before signing in" (+ resend action) | Sign In |
| Email already registered | code `user_already_exists` / `email_exists` (422) | "An account with this email already exists. Try signing in." | Sign Up |
| Weak password (server rule) | code `weak_password` | "Password is too weak. Use at least 8 characters with a letter and a number." | Sign Up |
| Rate limit (sign-up/resend/sign-in) | code `over_email_send_rate_limit` / `over_request_rate_limit` (HTTP 429) | "Too many attempts. Please wait a moment and try again." | Any |
| Network failure/timeout | `SocketException` / client timeout | "No connection. Check your internet and try again." | Any |
| Signups disabled | code `signup_disabled` | "Sign up is currently unavailable." | Sign Up |
| Expired/invalid confirmation link | deep link carries error (`otp_expired`, `access_denied`) | "This link is invalid or has expired" | Link landing |
| Anything else | any other `AuthException` or error | "Something went wrong. Please try again." | Any |

Rules: the data layer converts `AuthException` and network errors into `Failure` types; presentation maps `Failure` to the message above. Raw server messages are never shown to the user. Matching is by error code first, not by message text.

## 7. State requirements per screen

| Screen | Loading | Error | Success |
|---|---|---|---|
| Splash | Progress indicator while session resolves | If resolution throws, treat as signed out and go to Sign In | Home or Sign In |
| Sign Up | Button spinner, inputs disabled | Field errors; banner for server errors | Go to Check Your Email |
| Check Your Email | Resend button spinner | Banner for resend failure | "Confirmation email sent" message; countdown starts |
| Sign In | Button spinner, inputs disabled | Field errors; banner for server errors; unconfirmed variant with resend action | Go to Home |
| Home | Logout item shows progress inside the drawer | Local sign-out still happens (AC-26) | Go to Sign In |

## 8. Routes

`/` (splash/redirect), `/sign-in`, `/sign-up`, `/check-email`, `/home`. Constants live in `core/router/routes.dart`. `/otp`, `/forgot-password`, `/reset-password` are deferred.

## 9. Assumptions

- Email provider is enabled in the "Backary Project" Supabase project with the default "Confirm signup" template and "Confirm email" turned ON.
- The app deep link (e.g. `io.supabase.authapp://login-callback/`) is added by the Owner under Redirect URLs before T-07 testing.
- Supabase built-in mailer has a low hourly email limit; rate-limit errors are expected during testing.
- Sessions persist via `supabase_flutter` default local storage and refresh automatically.

## 10. Open questions: Answered by Owner (2026-10-21)

- OQ-01 (Answered: default accepted; Sign In with success message): After tapping the confirmation link, should the user be auto-signed-in (Supabase can return a session through the deep link) or be sent to Sign In to type their password? Draft AC-12 assumes sign-in screen with a success message; auto-login would be fewer steps.
- OQ-02 (Answered: show clear "already registered" message, as in section 6): Should the app reveal that an email is already registered (AC-05, better UX, allows account enumeration), or use a generic message? Supabase's own enumeration protection may return a fake success for confirmed emails; the draft shows the error only when Supabase returns it.
- OQ-03 (Answered: confirm-password field included): Is a "confirm password" field on Sign Up wanted? Draft includes it (AC-01); remove if you prefer a shorter form.
- OQ-04 (Answered: in memory only): Should the 60 s resend cooldown persist across app restarts? Draft says in-memory only (AC-10).
- OQ-05 (Answered: expired-link message + resend only): Should unconfirmed accounts that never confirm have any expiry behaviour in the app (Supabase link expiry defaults to 1 hour)? Draft only shows an expired-link message and allows resend.
- OQ-06 (Answered, changed from default): Home has an app bar with a hamburger icon on the left; the drawer contains Logout; the body is the user's email, centered. Reflected in AC-25, AC-25a, AC-25b, AC-26.
