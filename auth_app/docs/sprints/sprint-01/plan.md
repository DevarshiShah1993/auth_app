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
| T-01 | Write requirements + acceptance criteria for email sign-up with confirmation link, email sign-in (blocked until confirmed), session handling, logout (`docs/requirements/`) | BA | Todo | — |
| T-02 | Design spec: theme tokens (light/dark), sign-in, sign-up, check-your-email, home screens, states and animations (`docs/design/`) | Designer | Todo | T-01 (+ Owner gate 1) |
| T-03 | Project foundation: add dependencies, folder structure, `--dart-define` Supabase config, `get_it` setup, `main.dart`/`app.dart` | Developer | Todo | T-02 (+ Owner gate 2) |
| T-04 | Core theme + shared widgets: `ThemeData`, `AppTextField`, `PasswordField`, `PrimaryButton`, validators (`OtpInput` deferred to phone sprint) | Developer | Todo | T-03 |
| T-05 | Domain + data layer: `AppUser`, `AuthRepository`, `AuthRemoteDataSource`, `Failure` mapping, use cases (SignUp, SignInWithPassword, SignOut, ObserveAuthState) with unit tests | Developer | Todo | T-03 |
| T-06 | `AuthSessionBloc` + go_router auth guard (`routes.dart`, redirect, `refreshListenable`), placeholder Home page with logout | Developer | Todo | T-05 |
| T-07 | Sign-up + check-your-email screens: `SignUpBloc`, resend-confirmation action (60 s cooldown), deep-link config for `emailRedirectTo`, pages, bloc tests | Developer | Todo | T-04, T-05, T-06 |
| T-08 | Sign-in screen: `SignInBloc` (email + password), "please confirm your email" error state, page, bloc tests | Developer | Todo | T-04, T-05, T-06 |
| T-09 | QA: verify T-03–T-08 against acceptance criteria, run `flutter analyze` and `flutter test`, record verdicts and bugs (`bugs.md`) | QA | Todo | T-07, T-08 |

## Risks
- Supabase redirect URL (app deep link) must be added manually by the Owner before T-07 can be tested; deep link setup differs on Android/iOS. Built-in Supabase mailer has a low hourly email limit.
- Design and requirements gates may delay development start; T-03 cannot begin until both are approved.

## Decisions from Owner (2026-10-20)
- Vision file moved to `docs/vision.md`.
- Email sign-in is password-only after the account is verified (no OTP). **Changed 2026-10-20:** email OTP dropped (needs Supabase Pro); sign-up now uses the confirmation link, and the user can sign in only after tapping it.
- Supabase project "Backary Project" exists with the Email provider enabled. Remaining manual setup (Owner): add the app deep link under Authentication → URL Configuration → Redirect URLs (keep the default Confirm signup template), and provide the project URL + anon key via `--dart-define` / git-ignored `.env`. Needed before T-07 testing.

- **2026-10-20:** Phone OTP removed from the backend. Phone flows will be phone + password, followed by a stub OTP step where `111111` is accepted and everything else rejected (client-side, dev only). Phone sign-in/up and phone password reset stay out of Sprint 01 and will be planned in a later sprint (BA to capture in requirements; Supabase "Confirm phone" must be off).

## Questions for Owner
- None open.
