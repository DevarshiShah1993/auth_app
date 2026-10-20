# CLAUDE.md — Auth App (Flutter + Supabase)

## Project goal
Build the authentication module of a Flutter app using Supabase Auth.

Flows in scope:
1. Sign up: email + password, then email OTP verification
2. Sign up / sign in: phone number + OTP (SMS)
3. Sign in: email + password
4. Sign in: phone number + password, then OTP (2-step)
5. Forgot password: request OTP by email or phone, verify, set new password
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
- The redirect function decides based on `AuthSessionBloc` state: unauthenticated users only reach `/sign-in`, `/sign-up`, `/otp`, `/forgot-password`, `/reset-password`; authenticated users are redirected away from them.

## Supabase auth mapping (reference for Developer)
| Flow | Supabase call |
|---|---|
| Email sign up | `auth.signUp(email, password)` then `auth.verifyOTP(type: OtpType.signup, email, token)` |
| Email sign in | `auth.signInWithPassword(email, password)` |
| Phone sign in/up (OTP) | `auth.signInWithOtp(phone)` then `auth.verifyOTP(type: OtpType.sms, phone, token)` |
| Phone + password + OTP | `auth.signInWithPassword(phone, password)` for step 1, then the OTP step as above |
| Forgot password | `auth.resetPasswordForEmail(email)` or phone OTP, then `verifyOTP(type: OtpType.recovery)`, then `auth.updateUser(UserAttributes(password: new))` |
| Change password (logged in) | re-verify with `signInWithPassword(currentPassword)` then `auth.updateUser(...)` |
| Logout | `auth.signOut()` |

Prerequisites (manual, not for agents): enable Email and Phone providers in the Supabase dashboard, configure an SMS provider (e.g. Twilio) for phone OTP, set the email OTP template to include `{{ .Token }}`. Never commit keys.

## Security rules
- Supabase URL and anon key come from `--dart-define` or a git-ignored `.env`. Never hardcode, never commit service-role keys.
- Never log passwords, OTPs, or tokens.
- Validate input on the client (email format, password min 8 chars with letter and number, phone in E.164) but treat server errors as the source of truth.
- OTP screens: 6 digits, resend timer (60 s), max attempts message from server errors.

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
