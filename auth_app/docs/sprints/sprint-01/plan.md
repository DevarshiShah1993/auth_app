# Sprint 01 — Plan

_Owner of this file: PM. Source: `docs/vision.md` and `CLAUDE.md`._

## Goal
Deliver the **email + password sign-up (with email confirmation link) and sign-in flow end to end**, on top of a clean-architecture project foundation (theme, DI, router, session handling), so a user can create an account, confirm it via the emailed link, log in, stay logged in across launches, and log out.

Out of this sprint: phone auth, forgot password, change password (planned for later sprints).

## Human gates
1. Owner approves requirements (T-01) before design (T-02) starts.
2. Owner approves design (T-02) before any development task starts.
3. Owner approves PR merge after QA marks a task Done.

## Tasks

| ID | Task | Owner | Status | Depends on |
|---|---|---|---|---|
| T-01 | Write requirements + acceptance criteria for email sign-up with confirmation link, email sign-in (blocked until confirmed), session handling, logout (`docs/requirements/`) | BA | Done | — |
| T-02 | Design spec: theme tokens (light/dark), sign-in, sign-up, check-your-email, home screens, states and animations (`docs/design/`) | Designer | Done | T-01 (+ Owner gate 1) |
| T-03 | Project foundation: add dependencies, folder structure, `.env` Supabase config (`PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_PUBLISHABLE_KEY`; add `.env` to `.gitignore`, commit `.env.example`), `get_it` setup, `main.dart`/`app.dart` | Developer | Done | T-02 (+ Owner gate 2) |
| T-04 | Core theme + shared widgets: `ThemeData`, `AppTextField`, `PasswordField`, `PrimaryButton`, validators (`OtpInput` deferred to phone sprint) | Developer | Done | T-03 |
| T-05 | Domain + data layer: `AppUser`, `AuthRepository`, `AuthRemoteDataSource`, `Failure` mapping, use cases (SignUp, SignInWithPassword, SignOut, ObserveAuthState) with unit tests | Developer | Done | T-03 |
| T-06 | `AuthSessionBloc` + go_router auth guard (`routes.dart`, redirect, `refreshListenable`), placeholder Home page with logout | Developer | Done | T-05 |
| T-07 | Sign-up + check-your-email screens: `SignUpBloc`, resend-confirmation action (60 s cooldown), deep-link config for `emailRedirectTo`, pages, bloc tests | Developer | Done | T-04, T-05, T-06 |
| T-08 | Sign-in screen: `SignInBloc` (email + password), "please confirm your email" error state, page, bloc tests | Developer | Done | T-04, T-05, T-06 |
| T-10 | Follow-ups: `AppTextField` error-border-only state for server weak-password error; Android + iOS deep-link config for `io.supabase.authapp://login-callback/` so the confirmation link opens the app | Developer | Done | T-07, T-08 |
| T-11 | Fix QA bugs: B-01 (empty values in `.env.example`) and B-02 (forward only invalid-link errors from auth stream); un-skip the QA tests tied to them | Developer | Done | T-09 |
| T-09 | QA: verify T-03–T-08 against acceptance criteria, run `flutter analyze` and `flutter test`, record verdicts and bugs (`bugs.md`) | QA | Done | T-07, T-08, T-10 |

## Risks
- Supabase redirect URL (app deep link) must be added manually by the Owner before T-07 can be tested; deep link setup differs on Android/iOS. Built-in Supabase mailer has a low hourly email limit.
- Design and requirements gates may delay development start; T-03 cannot begin until both are approved.

## Decisions from Owner (2026-10-20)
- Vision file moved to `docs/vision.md`.
- Email sign-in is password-only after the account is verified (no OTP). **Changed 2026-10-20:** email OTP dropped (needs Supabase Pro); sign-up now uses the confirmation link, and the user can sign in only after tapping it.
- Supabase project "Backary Project" exists with the Email provider enabled. Remaining manual setup (Owner): add the app deep link under Authentication → URL Configuration → Redirect URLs (keep the default Confirm signup template), and add `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY` (new publishable key, not the legacy anon key) to the git-ignored `.env`. Needed before T-07 testing.

- **2026-10-20:** Phone OTP removed from the backend. Phone flows will be phone + password, followed by a stub OTP step where `111111` is accepted and everything else rejected (client-side, dev only). Phone sign-in/up and phone password reset stay out of Sprint 01 and will be planned in a later sprint (BA to capture in requirements; Supabase "Confirm phone" must be off).

- **2026-10-21:** Supabase config uses the new publishable key only (legacy anon key retired), read from `.env` as `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY`.

- **2026-10-23:** **Gate 1 closed.** Owner approved the T-01 requirements (`docs/requirements/sprint-01-email-auth.md`, incl. answers to OQ-01..06). T-02 started. Design must follow the "Modern Bakery SaaS" design system supplied by the Owner (Inter / JetBrains Mono, primary #D97706, secondary #475569, background #F8FAFC, surface #FFFFFF, text #0F172A, success #10B981, danger #EF4444, 6px radius, 1px #E2E8F0 borders, minimal shadows, 8px grid, flat buttons, outlined inputs with 2px primary focus ring). Designer to record it in `docs/design/`.
- T-01 shows `Ready for QA` because only QA may mark Done (PM cannot); Owner approval is recorded above.

- **2026-10-23:** **Gate 2 closed.** Owner answered every design question and approved the design (`docs/design/`). Decisions: bundle Inter + JetBrains Mono as assets (no google_fonts); derived dark palette, contrast deviations and extra shared widgets (InlineBanner, AuthScaffold, outlined PrimaryButton) approved; app name "Bakery"; Home title "Bakery ERP"; expired-link screen gets an email field to resend; no signed-out banner; email prefill only if the link carries it. Designer and BA are updating their docs to match. T-02 shows `Ready for QA` (PM cannot mark Done).
- T-03 is unblocked; Developer start awaits Owner go-ahead.

- **2026-10-23:** T-03 built on branch `sprint-01/T-03` (4 commits, not pushed): `flutter analyze` 0 issues, `flutter test` passes (3 tests). Exception: font files not added (see questions). Flutter lives at `/Users/devarshishah/Documents/Software/Flutter/flutter/bin` (not on shell PATH). Fresh clones must run `cp .env.example .env` before `flutter run` / `flutter test`.

- **2026-10-25:** T-03 follow-ups done by Developer: fonts declared in `pubspec.yaml` (Inter 400/500/600 24pt static, JetBrains Mono 400/500), `pubspec.lock` now tracked, `.env` confirmed ignored/untracked. `flutter analyze` 0 issues, `flutter test` passes. Unused font files left untracked for Owner to delete.

- **2026-10-25:** T-04 (branch `sprint-01/T-04`, 48 tests) and T-05 (branch `sprint-01/T-05`, 96 tests) built; `flutter analyze` 0 issues on both; not pushed. T-05 handles OQ-01 in `AuthRepositoryImpl`: a `signedIn` event not caused by an in-progress password sign-in (e.g. confirmation link) is signed out locally and reported on `emailLinkResults` as confirmed. T-04 and T-05 are separate branches (both from T-03) and are not yet merged together.

- **2026-10-25:** Owner approved: merge T-04 + T-05 into `sprint-01/integration` (done, no conflicts; `flutter analyze` 0 issues, 141 tests pass), T-04 colour picks approved, unused fonts deleted. T-06 started on `sprint-01/T-06` (from integration).

- **2026-10-25:** T-06 built on `sprint-01/T-06` (4 commits, 168 tests, `flutter analyze` 0 issues, not pushed). `AuthSessionState.linkResult` (`confirmed` / `invalid`, one-shot) is how T-07/T-08 get the email-link outcome: Sign In shows the "Email confirmed" banner, `/check-email` shows the expired-link variant, then dispatch `AuthSessionLinkResultConsumed`. Stub Sign In / Sign Up / Check Email pages exist for T-07/T-08 to replace.

- **2026-10-25:** Owner approved merging T-06 into `sprint-01/integration` (done; analyze clean, tests pass). T-07 started on `sprint-01/T-07`; T-08 follows on its own branch.

- **2026-10-25:** T-07 built on `sprint-01/T-07` (3 commits, 216 tests, analyze clean, not pushed). Email goes to `/check-email` as go_router `extra`. Known gap: server weak-password error shows banner only (no field error border; needs a shared-widget change); no screen-reader cooldown label. T-08 started on `sprint-01/T-08`, stacked on T-07 (needs T-07's shared `FailureMessages`, `AuthCard`, `SubmitStatus`); T-07 and T-08 are not yet merged into integration.

- **2026-10-25:** T-08 built on `sprint-01/T-08` (stacked on T-07; 2 commits, 240 tests, analyze clean, not pushed). Sign In shows the "Email confirmed" banner once and consumes it; `email_not_confirmed` offers Resend to `/check-email`. Minor deviation: shake plays on the failure banner, not the whole card. No device/simulator run yet. T-09 (QA) needs T-07 + T-08 merged into `sprint-01/integration`.

- **2026-10-27:** Owner approved: T-07 and T-08 merged into `sprint-01/integration` (analyze clean, 240 tests pass); add error-border-only state to `AppTextField`; redirect URL is added in Supabase and Developer may do deep-link setup. Added task T-10 (branch `sprint-01/T-10`, from integration) for those two follow-ups; T-09 (QA) now also depends on T-10.

- **2026-10-27:** T-10 built on `sprint-01/T-10` (2 commits, 243 tests, analyze clean, not pushed). `AppTextField.showErrorBorder` added and used for server weak-password on Sign Up. Android intent-filter + iOS URL scheme added; Flutter's own deep-link handling disabled so only supabase_flutter handles the link. iOS simulator build OK; Android not built (no adb / unaccepted licences); link delivery NOT tested on any device. Manual steps: Supabase Redirect URLs contains `io.supabase.authapp://login-callback/`; Android `adb shell am start -a android.intent.action.VIEW -d "io.supabase.authapp://login-callback/"`; iOS `xcrun simctl openurl booted "io.supabase.authapp://login-callback/"`; then the real flow (sign up, tap emailed link, expect Sign In with "Email confirmed" banner).

- **2026-10-29:** Owner approved merging T-10 into `sprint-01/integration` (done; analyze clean, 243 tests pass). iOS bundle id change deferred (not now). All dev tasks T-03..T-08 and T-10 are on the integration branch; T-09 (QA) is next.

- **2026-10-29:** Owner will test the deep link himself on an Android emulator (the missing `adb` in the agent shell is parked for later). T-09 (QA) started on `sprint-01/T-09` (from integration). QA records verdicts in `docs/sprints/sprint-01/bugs.md` and may update only the Status cell of T-01..T-10 in this plan (Done / Rejected) per the rule that only QA marks Done.

- **2026-10-31:** QA (T-09) verdicts recorded: T-03 Rejected (B-01), T-05 Rejected (B-02), others Done (see `bugs.md`). Owner decisions: (1) empty the values in `.env.example`; no key rotation (publishable key, accepted that values remain in git history); (2) `ObserveAuthState` / `ObserveEmailLinkResults` returning `Stream` is an accepted, documented exception to the `Future<Either>` use-case rule; (3) T-10 stays Done, Owner tests the Android deep link himself; (4) Developer fixes B-01 and B-02 as T-11 on `sprint-01/T-11` (from `sprint-01/T-09`), then QA re-verifies T-03 and T-05; (5) plan committed with these notes.

## Questions for Owner
- None open.
