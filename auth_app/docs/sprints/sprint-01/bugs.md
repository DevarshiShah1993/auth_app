# Sprint 01 — QA report and bugs (T-09)

_Owner of this file: QA. Date: 2026-10-29. Branch `sprint-01/T-09` (from `sprint-01/integration`)._

## 1. Run results

| Check | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test` | 266 passed, 2 skipped (skips are bug-linked: B-01, B-02), 0 failed |
| Tests before QA | 243 passed |
| Tests added by QA | `test/qa/architecture_rules_test.dart` (layer, security, config, deep-link checks), `test/qa/router_qa_test.dart` (AC-12/17/23/24/26/27), `test/qa/check_email_layout_qa_test.dart` (AC-13c, AC-30), plus one skipped test in `test/features/auth/data/repositories/auth_repository_impl_test.dart` (B-02) |

Not run (no device/Supabase access from QA): any real Supabase call, email delivery, deep link on a device, visual review. These are marked MANUAL below and are NOT claimed as passed.

## 2. Verdicts

| Task | Verdict | Notes |
|---|---|---|
| T-01 Requirements | Done | Consistent with code. Doc nit: AC-12 says "see OQ-03 for auto-login alternative" but the auto-login question is OQ-01 (OQ-03 is confirm-password). BA to fix wording; no behaviour impact. |
| T-02 Design | Done | Consistent with code. Known drift: sign-in failure shake plays on the banner, not the whole card (design says card `shake`); reported by Developer, accepted as minor. |
| T-03 Foundation | **Rejected** | B-01: `.env.example` has real values (AC-32, CLAUDE.md security rule). One-line fix. |
| T-04 Theme + shared widgets | Done | Widget tests, tokens, error-border state verified. |
| T-05 Domain + data | **Rejected** | B-02: any auth-stream error (e.g. offline token refresh) is reported as an email-link result, which makes the bloc/router show "Link expired" later. |
| T-06 Session bloc + router | Done | Verified by tests. Note: the offline scenario in B-02 surfaces here; re-verify together with the T-05 fix. |
| T-07 Sign-up + check-email | Done | Code and tests meet AC-01..AC-13f. End-to-end link delivery is MANUAL (see section 5). |
| T-08 Sign-in | Done | AC-14..AC-20 verified by widget/bloc tests. Server behaviour is MANUAL. |
| T-10 Follow-ups | Done (config) | Android/iOS config matches `AppConstants.authRedirectUrl` (test added). Delivery of the link to the app on a device is NOT verified; Owner is testing on Android. Reopen if that fails. |
| T-09 QA | Done | Matrix and verdicts complete. |

## 3. Bugs

### B-01 — `.env.example` is committed with real values
- Severity: Low (the URL and publishable key are public by design, not a secret), but it breaks an explicit rule.
- Task: T-03. **Blocks Done: yes** (AC-32: "`.env.example` with empty values is committed"; CLAUDE.md security rules).
- Steps: open `.env.example` (tracked since commit 7be3f1d).
- Expected: `PUBLIC_SUPABASE_URL=` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY=` with empty values.
- Actual: both lines hold the real project URL and a real `sb_publishable_...` key.
- Notes: values stay in git history after the fix; because it is a publishable key the Owner can decide whether rotating it is needed. `.env` itself is git-ignored and untracked (verified). `pubspec.yaml` lists `.env` as an asset, so the publishable values ship inside the app bundle (acceptable for a publishable key; see N-03).
- Test: `test/qa/architecture_rules_test.dart` ".env.example has the two keys with empty values" (skipped, B-01). Un-skip after the fix.

### B-02 — Auth-stream errors are treated as "email link invalid"
- Severity: Medium.
- Task: T-05 (root cause, `AuthRepositoryImpl._process`, `AuthEventType.error`), visible in T-06 (`AuthSessionBloc` maps every `Left` to `EmailLinkResult.invalid`). **Blocks Done: yes.**
- Steps: signed-in user whose stored token needs refreshing launches the app offline (gotrue emits a network error on `onAuthStateChange`, documented in gotrue). The user later logs out.
- Expected: logout goes to Sign In; network errors never produce a link result (AC-26, AC-13 applies only to link errors).
- Actual: the error becomes `Left(NetworkFailure)` on `emailLinkResults`, the bloc stores `linkResult = invalid`, and when the user is unauthenticated the router sends them once to `/check-email` in the "Link expired" variant instead of Sign In.
- Suggested fix (Developer): in the repository only forward errors that map to `InvalidLinkFailure` (and drop or log-free ignore the rest); optionally make the bloc ignore non-link failures.
- Test: `auth_repository_impl_test.dart` "a network error on the auth stream is not an email-link result" (skipped, B-02); confirmed failing when un-skipped.

## 4. Notes and risks (not bugs, no verdict impact)

- N-01 One public class per file: `AppTextField`/`AppTextFieldState` and `PasswordField`/`PasswordFieldState` share a file (State classes are public so `GlobalKey<...State>` works). Minor deviation from the rule.
- N-02 `ObserveAuthState` and `ObserveEmailLinkResults` return `Stream`, not `Future<Either<Failure,T>>`; documented in their doc comments. Deviation from the "use cases return Future<Either>" rule that the Owner should accept explicitly.
- N-03 `.env` is bundled as a Flutter asset (needed by `flutter_dotenv`). Only publishable values belong in it.
- N-04 OQ-02 / enumeration protection: for an already-confirmed email Supabase may return a fake success; the app then shows Check Your Email and no mail arrives. Accepted in the requirements note; MANUAL to observe.
- N-05 OQ-01 side effect: a `signedIn` event not caused by the app's own password sign-in is signed out locally. A signed-in user who taps another account's confirmation link is therefore logged out. Very rare; acceptable but worth knowing.
- N-06 OQ-01 race: `_expectingPasswordSignIn` is a single flag. If a link `signedIn` lands while a password sign-in is in flight and that sign-in then fails, the link session would be kept. Extremely unlikely; not reproduced.
- N-07 Cold start from the confirmation link: `onAuthStateChange` is a replay stream, so the bloc still sees the link's `signedIn` and signs out. But `getCurrentUser` at start could return the link's session first and flash Home briefly before the sign-out. Timing dependent; NOT VERIFIED (needs a device).
- N-08 iOS uses scenes (`UIApplicationSceneManifest`); whether `app_links` delivers custom-scheme URLs in that setup is NOT VERIFIED (iOS simulator `xcrun simctl openurl` test is in the MANUAL list).
- N-09 supabase_flutter logs the incoming link URI (which carries tokens) at `finest` level via the `logging` package. The app attaches no log listener, so nothing is printed. Do not add a `Logger.root.onRecord` printer without filtering.
- N-10 Authenticated user opening an unknown path is not redirected (go_router default error page). Not reachable today because Flutter deep-link routing is disabled; untested.

## 5. MANUAL / NOT VERIFIED checklist (Owner)

1. Android emulator: `adb shell am start -a android.intent.action.VIEW -d "io.supabase.authapp://login-callback/"` opens the app (no crash, stays on Sign In). Then the real flow: sign up with a real mailbox, tap the emailed link on the emulator, expect Sign In with "Email confirmed. You can now sign in." and no Home.
2. iOS simulator: `xcrun simctl openurl booted "io.supabase.authapp://login-callback/"` opens the app (N-08).
3. Real Supabase: sign up, Check Your Email with 60 s countdown, resend (success and rate-limit), sign in before confirming (expect "Please confirm your email" + Resend), confirm, sign in, restart app (auto-login to Home), logout, restart (Sign In).
4. Expired/used link: tap an old link, expect the "Link expired" variant with resend; try with the app closed (cold start) and open (N-07: no flash of Home).
5. Already registered email (N-04) and weak password from the server.
6. Offline: launch offline with a stored session, then log out (B-02 after the fix).
7. Visual review in light and dark on a small phone (360x640) with the keyboard open; confirm fonts load (Inter, JetBrains Mono) and animations stay under 400 ms. Automated tests only check for overflow/exceptions.
8. Confirm Supabase dashboard settings: Email provider on, "Confirm email" on, redirect URL listed, default "Confirm signup" template.

## 6. AC traceability matrix

Legend: test files are under `test/`. SU = `features/auth/presentation/pages/sign_up_page_test.dart`, SI = `.../sign_in_page_test.dart`, CE = `.../check_email_page_test.dart`, HP = `.../home_page_test.dart`, AS = `.../bloc/auth_session_bloc_test.dart`, CB/IB/UB = check_email / sign_in / sign_up bloc tests, RI = `features/auth/data/repositories/auth_repository_impl_test.dart`, AR = `core/router/app_router_test.dart`, AD = `core/router/auth_redirect_test.dart`, RQ = `qa/router_qa_test.dart`, ARCH = `qa/architecture_rules_test.dart`, CL = `qa/check_email_layout_qa_test.dart`, INSP = code inspection.

| AC | Coverage | Status |
|---|---|---|
| AC-01 | SU "shows fields, button and sign in link (AC-01)" | Pass |
| AC-02 | SU "empty submit ... no call (AC-02)", "mismatching confirm"; `core/utils/validators_test.dart` | Pass |
| AC-03 | SU "valid submit calls the use case", "loading disables fields (AC-03)"; INSP `AuthRemoteDataSourceImpl.signUp` passes `emailRedirectTo: AppConstants.authRedirectUrl` | Pass (real Supabase call MANUAL) |
| AC-04 | SU "success goes to check-email with the address as extra"; UB success; INSP no session handling on sign-up | Pass (no session on server: MANUAL) |
| AC-05 | SU "already registered shows banner"; RI mapping `user_already_exists`/`email_exists` | Pass (fake-success case N-04 MANUAL) |
| AC-06 | SU "password toggle (AC-06)"; `core/widgets/password_field_test.dart` "visibility resets" | Pass |
| AC-07 | CE "normal variant shows email, resend and back (AC-07)" | Pass |
| AC-08 | CE "resend sends, shows success..."; CB; INSP `resend(type: OtpType.signup)` | Pass (real send MANUAL) |
| AC-09 | UB "starts the cooldown"; CE countdown; `services/resend_cooldown_store_test.dart` | Pass |
| AC-10 | store test (per email, same run); CE "arriving during a cooldown" | Pass |
| AC-11 | CE "rate limit and network failures ... no cooldown"; CB failure paths | Pass |
| AC-12 | RI OQ-01 tests; AS link-result tests; SI "confirmed link shows the banner once", "link confirmed while the page is open"; RQ "confirmed link while on Sign Up lands on Sign In" | Pass in code; delivery of the link on a device MANUAL/NOT VERIFIED |
| AC-13 / 13a | CE "expired variant with known email (AC-13a)"; RI `otp_expired`/`access_denied` -> InvalidLinkFailure; AR "invalid link result opens check email once" | Pass (real expired link MANUAL) |
| AC-13b | CE "expired variant, unknown email: field, validation, resend" | Pass |
| AC-13c | CE (same) + CL "AC-13c: invalid email ... makes no call" | Pass |
| AC-13d | CE (same), CB | Pass |
| AC-13e | CE "Back to sign in navigates to sign in (AC-13e)" | Pass |
| AC-13f | AD "auth routes are reachable" / "splash and auth routes go to home"; RQ AC-24 | Pass |
| AC-14 | SI "shows fields, button and sign up link (AC-14)" | Pass |
| AC-15 | SI "empty submit ... (AC-15)"; validators | Pass |
| AC-16 | SI "loading disables fields and ignores a second submit (AC-16)"; IB | Pass |
| AC-17 | RQ "AC-17: after sign-in the stack cannot pop back"; AR; IB success | Pass |
| AC-18 | SI "wrong credentials: banner, password cleared, email kept"; RI mapping | Pass |
| AC-19 | SI "unconfirmed email shows resend action to check-email"; RI mapping `email_not_confirmed` | Pass (no session on server MANUAL) |
| AC-20 | SI "editing a field dismisses the banner (AC-20)"; SU same; IB dismiss | Pass |
| AC-21 | AR "shows splash while resolving"; `test/widget_test.dart`; AD | Pass (no visual flash: MANUAL) |
| AC-22 | AS start tests (user / null / failure); AD; AR "navigates from splash to sign in" | Pass (real stored session MANUAL) |
| AC-23 | AD; AR; RQ "public routes", "unknown route while signed out" | Pass |
| AC-24 | AD; AR; RQ "AC-24 ..." | Pass |
| AC-25 / 25a / 25b | HP "shows title, hamburger and centered email only", "hamburger opens drawer containing Log out" | Pass |
| AC-26 | HP "Log out dispatches logout", "drawer closes when logout finishes"; AS "logout success signs out", "logout failure still ends signed out"; RQ "AC-26/AC-27"; INSP gotrue `signOut` removes the local session before the network call | Pass; offline edge case affected by B-02 |
| AC-27 | AS user-changed tests; RQ "session ending moves Home to Sign In, no way back" | Pass (real refresh failure MANUAL) |
| AC-28 | AS tests (stream-driven); INSP `StreamRefreshListenable` in `app.dart` | Pass |
| AC-29 | page tests for loading/failure/success on SU, SI, CE, HP; `primary_button_test` | Pass |
| AC-30 | overflow tests: SU (both themes), SI, CE expired, CL (normal variant light/dark, long address), `auth_scaffold_test`; dark render tests | Pass for overflow/exceptions; visual review MANUAL |
| AC-31 | ARCH "no print/debugPrint/log"; INSP repository discards raw server messages (`AuthFailureMapper`); N-09 | Pass (crash/analytics: none present) |
| AC-32 | `env_config_test`; ARCH ".env is git-ignored and not tracked"; ARCH ".env.example ... empty values" (skipped) | **Fail: B-01** |
| AC-33 | ARCH "no service-role / secret / legacy anon key"; INSP `Supabase.initialize(publishableKey: ...)` | Pass |

## 7. Rule review (CLAUDE.md)

| Rule | Result |
|---|---|
| Domain pure Dart | Pass (ARCH test: imports only dart:, fpdart, equatable, own domain, core/error) |
| Only data (plus DI and `main.dart`) imports `supabase_flutter` | Pass (ARCH test) |
| Presentation never touches repositories/Supabase | Pass (ARCH test) |
| Use cases: one `call`, `Future<Either<Failure,T>>` | Pass except the two stream use cases (N-02) |
| get_it: repos/data sources `registerLazySingleton` on abstract types; Blocs `registerFactory` | Pass (ARCH test, `injection.dart`) |
| No hardcoded colours/text styles in pages | Pass (ARCH test) |
| No password/OTP/token logging | Pass (no print/log calls in `lib/`) |
| No `dynamic`; no unexplained `!` | Pass (`is!` only) |
| One public class per file | Minor deviation N-01 |
| Doc comments on public classes | Pass (sampled; theme extensions documented above `@immutable`) |
| `.env` ignored and untracked | Pass |
| `.env.example` empty values | **Fail B-01** |
| No legacy anon key / service-role key | Pass |
| Deep-link config matches `AppConstants.authRedirectUrl` | Pass (ARCH tests for AndroidManifest and Info.plist; delivery MANUAL) |
