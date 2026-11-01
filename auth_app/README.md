# Bakery Auth — Flutter + Supabase Authentication Module

A production-style authentication module for a Flutter app ("Bakery ERP"), built on **Supabase Auth** with **Clean Architecture**, and delivered through a **multi-agent software team**: a Product Manager, Business Analyst, Designer, Developer and QA, each an AI agent with its own role, file ownership and handoff rules.

This repository is both the app and the paper trail of how it was built. Every requirement, design decision, sprint plan, bug and verdict is a file in [`docs/`](docs).

---

## Highlights

- **Email + password sign-up with a confirmation link.** The user can sign in only after tapping the emailed link, which opens the app through a deep link.
- **Check-your-email screen** with a 60-second resend cooldown and an expired-link recovery variant.
- **Email + password sign-in** with distinct handling for wrong credentials, unconfirmed email, rate limits and network failures.
- **Session handling:** auto-login on launch, auth-guarded routes driven by a `go_router` redirect, logout, and sign-out when the session ends elsewhere.
- **Clean Architecture, enforced by tests.** Layer rules are asserted by automated architecture tests, not just by convention.
- **Custom Material 3 design system** ("Modern Bakery SaaS"), light and dark, with WCAG contrast fixes documented by the Designer agent.
- **272 automated tests passing, `flutter analyze` at 0 issues** (QA re-verification, 2026-10-31).

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter, null-safe Dart |
| Backend | Supabase (`supabase_flutter`), publishable key only |
| State management | `flutter_bloc` + `equatable` |
| Navigation | `go_router` (redirect-based auth guard) |
| Dependency injection | `get_it` |
| Functional errors | `fpdart` (`Either<Failure, T>`) |
| UI and animation | Material 3 custom theme + `flutter_animate` |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |

## Architecture

Feature-first Clean Architecture. Dependencies point inward only: `presentation → domain ← data`.

```
lib/
├── core/
│   ├── di/            get_it registrations
│   ├── error/         typed Failures (invalid credentials, email not confirmed, rate limit, ...)
│   ├── router/        go_router, auth redirect, refresh listenable
│   ├── theme/         colors, text styles, spacing, motion, ThemeData (light + dark)
│   ├── widgets/       AppTextField, PasswordField, PrimaryButton, InlineBanner, AuthScaffold
│   └── utils/         validators, env config, constants
└── features/auth/
    ├── domain/        AppUser, AuthRepository (abstract), use cases   (pure Dart)
    ├── data/          Supabase data source, models, failure mapper, repository impl
    └── presentation/  AuthSessionBloc, SignInBloc, SignUpBloc, CheckEmailBloc, pages
```

Rules that are enforced (see `test/qa/architecture_rules_test.dart`):

- `domain` imports only Dart, `fpdart`, `equatable` and its own code.
- Only `data` (plus DI and `main.dart`) imports `supabase_flutter`.
- Presentation never touches repositories or Supabase directly: UI → Bloc → UseCase → Repository.
- No hardcoded colors or text styles in pages; no `print`/`log` calls (nothing can leak a password or token).
- Supabase `AuthException`s are mapped to typed `Failure`s by error code, never by message text. Raw server messages are never shown to users.

## How it was built: a five-agent team

The project was run like a small software company. Five agents, defined in [`.claude/agents/`](.claude/agents), each own specific folders and are forbidden from touching the others'. They never talk directly: **all communication happens through files in `docs/`**, so every decision is written down.

| Agent | Owns | Must not | What it produced |
|---|---|---|---|
| **PM** | `docs/sprints/**` | write code or requirements | Sprint plan, task breakdown with dependencies, risks, a decision log of every Owner call |
| **BA** | `docs/requirements/**` | write code or design | 33 numbered acceptance criteria, user stories, validation rules, error-mapping table, open questions |
| **Designer** | `docs/design/**` | change requirements | Design system, screen specs, light/dark tokens, animation specs, accessibility fixes |
| **Developer** | `lib/**`, `test/**` | edit acceptance criteria or QA verdicts | The app and its unit/widget/bloc tests |
| **QA** | extra tests, `bugs.md` | edit production code | Independent verification, AC traceability matrix, bug reports, verdicts |

### The workflow

```
Vision ─► PM plans sprint ─► BA writes requirements ─► [Owner gate 1]
      ─► Designer writes design ─► [Owner gate 2] ─► Developer builds T-03..T-08, T-10
      ─► QA verifies ─► bugs found ─► Developer fixes (T-11) ─► QA re-verifies ─► [Owner gate 3: PR merge]
```

Guardrails that made the process trustworthy:

- **Three human gates.** The Owner (me) approved requirements before design, design before development, and the PR merge after QA.
- **Separation of duties.** Only QA can mark a task `Done`. The PM never can, and the Developer cannot edit acceptance criteria or bug verdicts.
- **Status machine:** `Todo → In Progress → Ready for QA → Done | Rejected | Blocked`.
- **Branch discipline.** One feature branch per task (`sprint-01/T-07`), small commits prefixed with the task ID (`T-05: add auth data source...`), merged through an integration branch and a pull request. Nothing was committed to `main` directly.
- **Questions go in writing.** When an agent was unsure, it wrote the question for the Owner instead of guessing. Examples: should the user be auto-signed-in after tapping the link? Should the app reveal that an email is already registered?

### What each agent contributed

**PM.** Turned [`docs/vision.md`](docs/vision.md) into [Sprint 01](docs/sprints/sprint-01/plan.md): 11 tasks (T-01 to T-11) with owners, dependencies and gates. It kept a dated decision log, for example the 2026-10-20 change that dropped email OTP (it needs Supabase Pro) in favour of confirmation links, and the 2026-10-21 switch to Supabase's new publishable key.

**BA.** Wrote [the requirements](docs/requirements/sprint-01-email-auth.md): 7 user stories, 33 acceptance criteria (`AC-01` to `AC-33`), client-side validation rules and a table mapping each Supabase error code to a user-facing message. Six open questions (`OQ-01` to `OQ-06`) were answered by the Owner before design started.

**Designer.** Wrote [the design system](docs/design/design-system.md) and [screen specs](docs/design/sprint-01-screens.md). The Designer didn't just apply the supplied palette: it audited it against WCAG and recorded the conflicts, for example white-on-amber text at 3.2:1 (failed, so button labels use dark slate at 5.6:1), idle input borders at 1.2:1 (failed, so inputs use a darker outline), and touch targets kept to 48dp even in a dense visual style. It also derived the dark palette and defined every animation under 400 ms.

**Developer.** Built the app in task order: foundation and DI (T-03), theme and shared widgets (T-04), domain and data layers (T-05), session bloc and router guard (T-06), sign-up and check-email (T-07), sign-in (T-08), and Android/iOS deep-link config (T-10). Each task ended with `flutter analyze` clean and tests passing.

**QA.** Wrote [the QA report](docs/sprints/sprint-01/bugs.md): a traceability matrix mapping every acceptance criterion to a specific test, plus its own test suites (architecture rules, router behaviour, small-screen layout). QA **rejected two tasks on the first pass**:

- **B-01 (Low):** `.env.example` had been committed with real values, violating an explicit security rule.
- **B-02 (Medium):** a network error on the auth stream was misread as an "email link expired" event, so a user logging out after an offline launch landed on the wrong screen.

The Developer fixed both in T-11, QA re-verified, and both tasks moved to `Done`. QA also listed what it could **not** verify (real email delivery, deep links on a device, visual review) as a manual checklist rather than claiming a pass.

## Security

- Supabase config is read from a git-ignored `.env` with exactly two keys: `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY`. Only the publishable key is used. No service-role or legacy `anon` key is in the repo, and a test checks for that.
- The app fails fast with a clear developer error if either value is missing.
- Passwords, tokens and sessions are never logged.
- Client-side validation (email format, password of 8+ characters with a letter and a number) is a convenience only; server errors are the source of truth.

## Running it

Prerequisites: Flutter (stable) and a Supabase project with the Email provider enabled, "Confirm email" on, the default "Confirm signup" template, and `io.supabase.authapp://login-callback/` added under Authentication → URL Configuration → Redirect URLs.

```bash
cp .env.example .env     # then fill in the two values
flutter pub get
flutter run
```

```bash
flutter analyze
flutter test
```

## Status and roadmap

**Sprint 01 (done):** email sign-up with confirmation link, check-email with resend, email sign-in, auto-login, auth-guarded routing, logout.

**Not yet verified on a real device** (tracked in `bugs.md` §5): delivery of the confirmation link to the app on Android and iOS, real email sending, and visual review on a small phone.

**Planned for later sprints** (specified in `CLAUDE.md`, not built yet):

- Phone number + password sign-up and sign-in with a stub OTP step (`111111`, dev only, build-flag gated, no SMS)
- Forgot password by email link, and change password while logged in
- Social login, biometrics and profile editing are out of scope for now.

## Repository map

| Path | Contents |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | The project rules every agent follows: stack, architecture, security, workflow, Definition of Done |
| [`.claude/agents/`](.claude/agents) | The five agent definitions (PM, BA, Designer, Developer, QA) |
| [`docs/vision.md`](docs/vision.md) | Product vision |
| [`docs/requirements/`](docs/requirements) | BA output: user stories, acceptance criteria |
| [`docs/design/`](docs/design) | Designer output: design system, screen specs |
| [`docs/sprints/sprint-01/`](docs/sprints/sprint-01) | PM plan and QA bug report |
| `lib/`, `test/` | The app and its tests |
