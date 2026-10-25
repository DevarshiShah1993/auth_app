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
| T-01 | Write requirements + acceptance criteria for email sign-up with confirmation link, email sign-in (blocked until confirmed), session handling, logout (`docs/requirements/`) | BA | Ready for QA | — |
| T-02 | Design spec: theme tokens (light/dark), sign-in, sign-up, check-your-email, home screens, states and animations (`docs/design/`) | Designer | Ready for QA | T-01 (+ Owner gate 1) |
| T-03 | Project foundation: add dependencies, folder structure, `.env` Supabase config (`PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_PUBLISHABLE_KEY`; add `.env` to `.gitignore`, commit `.env.example`), `get_it` setup, `main.dart`/`app.dart` | Developer | Ready for QA | T-02 (+ Owner gate 2) |
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
- Supabase project "Backary Project" exists with the Email provider enabled. Remaining manual setup (Owner): add the app deep link under Authentication → URL Configuration → Redirect URLs (keep the default Confirm signup template), and add `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY` (new publishable key, not the legacy anon key) to the git-ignored `.env`. Needed before T-07 testing.

- **2026-10-20:** Phone OTP removed from the backend. Phone flows will be phone + password, followed by a stub OTP step where `111111` is accepted and everything else rejected (client-side, dev only). Phone sign-in/up and phone password reset stay out of Sprint 01 and will be planned in a later sprint (BA to capture in requirements; Supabase "Confirm phone" must be off).

- **2026-10-21:** Supabase config uses the new publishable key only (legacy anon key retired), read from `.env` as `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY`.

- **2026-10-23:** **Gate 1 closed.** Owner approved the T-01 requirements (`docs/requirements/sprint-01-email-auth.md`, incl. answers to OQ-01..06). T-02 started. Design must follow the "Modern Bakery SaaS" design system supplied by the Owner (Inter / JetBrains Mono, primary #D97706, secondary #475569, background #F8FAFC, surface #FFFFFF, text #0F172A, success #10B981, danger #EF4444, 6px radius, 1px #E2E8F0 borders, minimal shadows, 8px grid, flat buttons, outlined inputs with 2px primary focus ring). Designer to record it in `docs/design/`.
- T-01 shows `Ready for QA` because only QA may mark Done (PM cannot); Owner approval is recorded above.

- **2026-10-23:** **Gate 2 closed.** Owner answered every design question and approved the design (`docs/design/`). Decisions: bundle Inter + JetBrains Mono as assets (no google_fonts); derived dark palette, contrast deviations and extra shared widgets (InlineBanner, AuthScaffold, outlined PrimaryButton) approved; app name "Bakery"; Home title "Bakery ERP"; expired-link screen gets an email field to resend; no signed-out banner; email prefill only if the link carries it. Designer and BA are updating their docs to match. T-02 shows `Ready for QA` (PM cannot mark Done).
- T-03 is unblocked; Developer start awaits Owner go-ahead.

- **2026-10-23:** T-03 built on branch `sprint-01/T-03` (4 commits, not pushed): `flutter analyze` 0 issues, `flutter test` passes (3 tests). Exception: font files not added (see questions). Flutter lives at `/Users/devarshishah/Documents/Software/Flutter/flutter/bin` (not on shell PATH). Fresh clones must run `cp .env.example .env` before `flutter run` / `flutter test`.

- **2026-10-25:** T-03 follow-ups done by Developer: fonts declared in `pubspec.yaml` (Inter 400/500/600 24pt static, JetBrains Mono 400/500), `pubspec.lock` now tracked, `.env` confirmed ignored/untracked. `flutter analyze` 0 issues, `flutter test` passes. Unused font files left untracked for Owner to delete.

## Questions for Owner
- `.env.example` in the working tree contains non-empty Supabase values (uncommitted). It must hold empty values per CLAUDE.md: restore it with `git checkout .env.example`, keeping real values only in `.env`. Owner to confirm.
- Delete unused font files from `assets/fonts/` (Inter 18pt/28pt, other Inter 24pt weights and italics, JetBrains Mono except Regular/Medium).
