# CLAUDE.md — Auth App (Flutter + Supabase)

## Project goal
Build the authentication module of a Flutter app using Supabase Auth.

Flows in scope:
1. Sign up: email + password, then email confirmation link (no email OTP; the user can sign in only after tapping the link)
2. Sign up: phone number + password, then stub OTP step (no SMS; see "Phone OTP stub")
3. Sign in: email + password
4. Sign in: phone number + password, then stub OTP step (2-step)
5. Forgot password: request a reset link by email, set new password (phone reset deferred until a real SMS provider exists)
6. Change password while logged in (Settings), asks for current password first
7. Session handling: auto-login on launch, logout, auth-guarded routes

Out of scope for now: social login, biometrics, profile editing.

## Tech stack (do not swap without asking the PM)
| Concern | Choice |
|---|---|
| Framework | Flutter (stable), Dart null-safe |
| Backend | Supabase (`supabase_flutter`) |
| State management | `flutter_bloc` (+ `equatable`) |
| Navigation | `go_router` (redirect-based auth guard) |
| Dependency injection | `get_it` |
| Functional errors | `fpdart` (`Either<Failure, T>`) |
| Design + animation | Material 3 custom theme + `flutter_animate` |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |

## Architecture: Clean Architecture, feature-first
```
lib/
├── main.dart
├── app.dart                      # MaterialApp.router
├── core/
│   ├── di/injection.dart         # get_it registrations
│   ├── error/                    # Failure, exceptions
│   ├── router/app_router.dart    # go_router + auth redirect
│   ├── theme/                    # colors, text styles, ThemeData
│   ├── widgets/                  # shared widgets (buttons, fields, otp input)
│   └── utils/                    # validators, constants
└── features/
    └── auth/
        ├── domain/
        │   ├── entities/         # AppUser (pure Dart)
        │   ├── repositories/     # AuthRepository (abstract)
        │   └── usecases/         # one class per use case
        ├── data/
        │   ├── datasources/      # AuthRemoteDataSource (Supabase calls only here)
        │   ├── models/           # UserModel (extends/maps to AppUser)
        │   └── repositories/     # AuthRepositoryImpl
        └── presentation/
            ├── bloc/             # AuthSessionBloc, SignInBloc, SignUpBloc, OtpBloc, PasswordBloc
            ├── pages/
            └── widgets/
test/                             # mirrors lib/
```

### Layer rules (strict)
- `domain` is pure Dart: no Flutter, no Supabase, no `get_it` imports.
- `data` is the only layer that imports `supabase_flutter`. Convert Supabase exceptions (`AuthException`) to `Failure` in the data source / repository.
- `presentation` never calls Supabase or repositories directly. UI → Bloc → UseCase → Repository.
- Use cases return `Future<Either<Failure, T>>`, one public method `call(Params)`.
- Dependencies point inward only: presentation → domain ← data.
- Repositories and data sources are registered against their abstract type in `get_it`. Blocs are `registerFactory`; repositories and data sources are `registerLazySingleton`.

### Bloc rules
- One Bloc per concern. Events are verbs (`SignInSubmitted`), states are immutable and `Equatable`.
- States carry a status (`initial`, `loading`, `success`, `failure`) plus an optional `Failure`. No business logic in widgets.
- `AuthSessionBloc` listens to `supabase.auth.onAuthStateChange` (through the repository's stream) and drives the router redirect via a `refreshListenable`.

### Routing rules
- Routes are constants in `core/router/routes.dart`; navigate with `context.go` / `context.push` by name.
- The redirect function decides based on `AuthSessionBloc` state: unauthenticated users only reach `/sign-in`, `/sign-up`, `/check-email`, `/otp` (phone only), `/forgot-password`, `/reset-password`; authenticated users are redirected away from them.

## Supabase auth mapping (reference for Developer)
| Flow | Supabase call |
|---|---|
| Email sign up | `auth.signUp(email, password, emailRedirectTo: <app deep link>)`; Supabase emails a confirmation link. No `verifyOTP`. Until confirmed, `signInWithPassword` fails with `email_not_confirmed` (map to a "please confirm your email" Failure) |
| Email sign in | `auth.signInWithPassword(email, password)` |
| Phone sign up | `auth.signUp(phone, password)` (phone confirmation must be disabled in Supabase, so no SMS is sent), then the stub OTP step |
| Phone sign in | `auth.signInWithPassword(phone, password)`, then the stub OTP step |
| Forgot password | email: `auth.resetPasswordForEmail(email, redirectTo: <app deep link>)`, the link opens the app with a recovery session; phone reset is deferred; then `auth.updateUser(UserAttributes(password: new))` |
| Change password (logged in) | re-verify with `signInWithPassword(currentPassword)` then `auth.updateUser(...)` |
| Logout | `auth.signOut()` |

Prerequisites (manual, not for agents): enable Email and Phone providers in the Supabase dashboard and turn OFF "Confirm phone" (no SMS provider is used), add the app deep link (e.g. `io.supabase.authapp://login-callback/`) to Authentication → URL Configuration → Redirect URLs, and keep the default "Confirm signup" email template (it contains the link). Email OTP/`{{ .Token }}` is not used. Never commit keys.

## Security rules
- Supabase config comes from a git-ignored `.env` file with exactly two keys: `PUBLIC_SUPABASE_URL` and `PUBLIC_SUPABASE_PUBLISHABLE_KEY`. Use the new **publishable key only**; the legacy `anon` key must not be used (Supabase is retiring it). Never hardcode keys, never commit `.env` (commit a `.env.example` with empty values), never use or commit a secret / service-role key. `--dart-define` remains only for build flags such as `USE_STUB_OTP`.
- Never log passwords, OTPs, or tokens.
- Validate input on the client (email format, password min 8 chars with letter and number, phone in E.164) but treat server errors as the source of truth.
- Phone OTP screens: 6 digits, resend timer (60 s), max attempts message after 5 wrong tries (client-side while stubbed).

## Phone OTP stub (temporary, dev only)
- No SMS/OTP is sent by the backend. The OTP step is checked on the client by an `OtpVerifier` abstraction (domain) with a `FixedOtpVerifier` (data) where **`111111` is the only valid code; anything else is wrong**.
- The stub is NOT security. It only gates the UI step, so the password sign-in already created a session. Treat phone accounts as password-protected only.
- Register `FixedOtpVerifier` in `get_it` only when a build flag (e.g. `--dart-define=USE_STUB_OTP=true`) is set; release builds must not ship it. Swapping to a real provider later must need no changes outside data/DI.
- The code `111111` is a documented dev constant, not a secret, but must not be logged with user data.

## UI and animation guidelines
- Material 3, one `ThemeData` in `core/theme`, light and dark. No hardcoded colors or text styles in pages.
- Shared widgets in `core/widgets`: `AppTextField`, `PasswordField` (toggle), `PrimaryButton` (loading state), `OtpInput`.
- Use `flutter_animate` sparingly: fade + slide-in on page content, shake on validation error, button loading transition. Keep each effect under 400 ms. No animation logic inside Blocs.
- Every screen needs loading, error, and success states, and must work on small phones and with the keyboard open.

## Code standards
- `flutter analyze` must be clean. Use `flutter_lints` (or stricter).
- Prefer `const` constructors. Files in `snake_case`. One public class per file.
- No `dynamic`, no `!` null-assertion without a comment explaining why.
- Public classes and use cases get short doc comments.

## Definition of Done (per task)
1. Acceptance criteria in `docs/requirements/` are all met.
2. `flutter analyze` has 0 issues.
3. `flutter test` passes; new use cases and Blocs have unit tests (success + each failure path).
4. Layer rules above are respected.
5. Task status updated in the sprint plan; QA verdict recorded.

## Multi-agent workflow

### Roles and write permissions
| Agent | Owns / writes | Must not |
|---|---|---|
| PM | `docs/sprints/**` (plan, daily, retro) | write product code or requirements |
| BA | `docs/requirements/**` | write code or design |
| Designer | `docs/design/**`, `core/theme` spec | change requirements |
| Developer | `lib/**`, `test/**` | edit acceptance criteria or bugs.md verdicts |
| QA | extra tests in `test/**`, `docs/sprints/**/bugs.md` | edit production code in `lib/**` |

### Handoff rules
- Agents communicate only through files in `docs/`. Do not assume another agent remembers anything.
- Task statuses: `Todo → In Progress → Ready for QA → Done | Rejected | Blocked`.
- A task moves to `Done` only by QA. The PM never marks work Done.
- If anything is unclear, write the question under "Questions for Owner" in today's daily report instead of guessing.
- Work happens on a feature branch (`sprint-XX/<task-id>`), never on `main`. Small commits with the task ID in the message, e.g. `T-03: add SignInWithPassword use case`.

### Human gates (the Owner approves)
1. Requirements before design starts.
2. Design before development starts.
3. PR merge after QA marks the task Done.

### Daily report format (`docs/sprints/sprint-XX/daily/YYYY-MM-DD.md`)
Done yesterday, In progress, Blocked, Bugs found, Risks, Questions for Owner, Proposed plan for today.
