# Sprint 01 Screen Specs (T-02)

_Owner of this file: Designer. Status: Approved by Owner (Gate 2), decisions of 2026-10-23 applied. Tokens, widgets and theme: `design-system.md`. Requirements: `docs/requirements/sprint-01-email-auth.md` (AC ids referenced). Nothing here changes requirements._

## 0. Global rules

- Reference devices: 360x640 logical px (smallest), 393x852, tablet 768 wide. Light and dark.
- `AuthScaffold`: `Scaffold` (`resizeToAvoidBottomInset: true`) > `SafeArea` > `SingleChildScrollView` (`keyboardDismissBehavior: onDrag`, `padding` 16 gutters, bottom padding = 16 + `viewInsets.bottom` handled by the scaffold) > `Center` > `ConstrainedBox(maxWidth 400)`. Content is top-aligned with 24dp top padding when the keyboard is open or the screen is short, vertically centered when there is room (use `LayoutBuilder` + `ConstrainedBox(minHeight)` + `IntrinsicHeight`-free `Column` with `MainAxisAlignment.center`). Never a fixed-height layout; submit must stay reachable by scrolling and via keyboard "done".
- On focus, the focused field is scrolled into view (default `ensureVisible`) with 16dp margin above the keyboard.
- Form card: auth forms sit on a card (`surface`, 1px `outlineVariant`, radius 6, card shadow, padding 24; 16 on <= 360 wide). Page background #F8FAFC.
- Page content enters with `pageIn`/`staggerIn`. No animation on rebuilds caused by typing.
- Banners (`InlineBanner`) sit at the top of the card, above the first field, and are dismissed on any field edit or resubmit (AC-20), exiting with a 150 ms fade.
- All navigation between auth screens: `context.go` by route name; Sign In <-> Sign Up use the same `pageIn` (no custom transition).
- Strings are final copy unless marked (draft).

## 1. Splash (session resolving; AC-21, AC-22)

- Layout: full screen `scaffoldBackground`, centered column: 48dp icon tile (primaryContainer, 6 radius, lock icon in primaryText) + 24dp gap + `CircularProgressIndicator` 24dp (primary, stroke 2). No text needed; semantics label "Loading".
- Motion: tile `fadeIn` 200 ms. No slide (avoid flash/jank). Hold minimum 0 ms; do not artificially delay.
- States: loading only. If resolution throws, router goes to Sign In (no error UI).
- Dark: same with dark tokens.

## 2. Sign In (`/sign-in`; AC-14..AC-20)

### Layout (top to bottom, inside the card)
1. Icon tile (48x48, primaryContainer fill, `lock_outline` 24dp primaryText) , 16 gap.
2. Title "Sign in" (headlineMedium), 8 gap, subtitle "Welcome back. Enter your details to continue." (bodyMedium, onSurfaceVariant). 24 gap.
3. [Banner slot] error / success / unconfirmed variant (see states). 16 gap when present.
4. `AppTextField` Email (label "Email"). 16 gap.
5. `PasswordField` (label "Password"). 24 gap. (No forgot-password link this sprint, AC-14.)
6. `PrimaryButton` "Sign in" (full width, 48dp).
- Below the card (outside, 16 gap): centered row "Don't have an account?" (bodyMedium secondary) + `TextButton` "Sign up" (48dp tall). Wraps to two lines on narrow widths / large text.

Small phone, keyboard open (360x640, keyboard about 260dp, usable about 330dp): icon tile hides when `viewInsets.bottom > 0` and height < 700 (fade 150 ms) to recover 64dp; title + subtitle + 2 fields + button = about 24+36+8+20+24+48+16+48+24+48 = 296dp, fits; sign-up link reachable by scroll.

### States
| State | Visual |
|---|---|
| Initial | Empty fields, nothing focused. Autofocus none (avoids keyboard covering the screen on entry). |
| Typing | Field focus ring 2px primary. Errors for that field clear on edit (not before). |
| Validation error (on blur/submit; AC-15) | Field error border + icon + text ("Enter a valid email address" / "Enter your password"); first invalid field gets focus; invalid fields `shake` once (320 ms); no network. |
| Loading (AC-16) | Fields disabled (disabled style), button shows spinner (`buttonLoading`), link "Sign up" disabled, keyboard dismissed. Back not blocked by app, but a second submit is ignored. |
| Failure: wrong credentials (AC-18) | Error banner "Incorrect email or password" (errorIn + card `shake` 320 ms). Password field cleared and focused; email kept. |
| Failure: unconfirmed (AC-19) | Banner (error variant, warning icon `mark_email_unread`) "Please confirm your email before signing in" with trailing text action "Resend confirmation email" (48dp tall) which goes to `/check-email` for that address. Fields re-enabled; password kept (not cleared; no credential error). |
| Failure: rate limit / network / other | Error banner with the section 6 message: "Too many attempts. Please wait a moment and try again." / "No connection. Check your internet and try again." / "Something went wrong. Please try again." Fields re-enabled and values kept. |
| Success (AC-17) | Spinner stays until navigation to Home (`go`, so back cannot return). No success toast. |
| From confirmation link (AC-12) | Success banner (variant success, `check_circle` icon) "Email confirmed. You can now sign in." shown at banner slot on arrival (successIn); email field prefilled with the confirmed address if known; dismissed on edit. Message is announced via live region. |
| From link error (AC-13) | See section 4 for where the expired-link error lives. |

### Motion
pageIn on card (300 ms), stagger on children (40 ms steps), shake on invalid fields/banner failure, button loading swap (200 ms). Banners: errorIn 200 ms.

### Accessibility specifics
Tab order: email, password, Sign in, Sign up. Enter on password submits. `autofillHints` email/password with `AutofillGroup`. Banner is a live region.

## 3. Sign Up (`/sign-up`; AC-01..AC-06)

### Layout
1. Icon tile (`person_add_alt` ) , title "Create account", subtitle "Sign up with your email. We will send you a confirmation link."
2. [Banner slot].
3. `AppTextField` Email.
4. `PasswordField` "Password" with persistent helper "At least 8 characters, with a letter and a number".
5. `PasswordField` "Confirm password".
6. `PrimaryButton` "Sign up".
- Below the card: "Already have an account?" + `TextButton` "Sign in".
- Both password toggles are independent. Confirm field `textInputAction.done`.

Small phone/keyboard: three fields (3x48 + 2x16 + helper 20) about 196dp + title block 64 + button 72 = about 330dp: just fits on 360x640 with keyboard (usable about 330); scroll covers the remainder; icon tile hidden while keyboard visible, subtitle also collapses when `height < 640` and keyboard open (title stays).

### Validation (AC-02, section 4)
Run on blur and submit; clear on edit. Messages verbatim from requirements. Confirm-password re-validates when the password field changes (only once confirm has been touched). Shake on each newly invalid field; focus moves to first invalid field.

### States
| State | Visual |
|---|---|
| Initial | Empty; helper text visible under password. |
| Loading (AC-03) | Fields disabled, button spinner, link disabled. |
| Failure: already registered (AC-05) | Banner "An account with this email already exists. Try signing in." with trailing text action "Sign in" (goes to `/sign-in`, email carried over). Shake card; fields re-enabled; values kept. |
| Failure: weak password (server) | Banner "Password is too weak. Use at least 8 characters with a letter and a number." and the password field shows error border (no duplicate text under field). |
| Failure: rate limit / network / signup disabled / other | Banner with section 6 text. |
| Success (AC-04) | Navigate (`go`) to `/check-email` with the address; passwords are cleared from memory/controllers on leaving. No Home. |

Motion identical to Sign In. Password visibility resets when the page is disposed (AC-06).

## 4. Check your email (`/check-email`; AC-07..AC-13)

### Layout (inside card, centered text)
1. Icon tile 56x56 (primaryContainer, `mark_email_read_outlined` 28dp, primaryText), `successIn` 300 ms.
2. Title "Check your email" (headlineMedium, centered).
3. Body: "We sent a confirmation link to" (bodyMedium, secondary) then the address in `dataSmall` (JetBrains Mono 14, onSurface, `SelectableText`, wraps with `softWrap`, up to 2 lines then ellipsis not used; wrap fully).
4. Instruction: "Tap the link in the email to confirm your account, then sign in." (bodyMedium, secondary). Mention spam: "Can't find it? Check your spam folder." (bodySmall... use bodyMedium to stay accessible).
5. [Banner slot] for resend success/failure.
6. `PrimaryButton` (outlined variant) "Resend email" (full width, 48dp). Label while cooling down: "Resend email in 0:42" where the time is `dataSmall`-style tabular digits (fixed width so label does not jitter).
7. `TextButton` "Back to sign in" (48dp, centered), 8 gap above.

Small phone / keyboard: no inputs on this screen (except expired variant below); content about 56+24+36+...= under 420dp, scrolls if needed.

### Cooldown (AC-09..AC-11)
- Starts at 60 s when sign-up succeeds and on each accepted resend; held in memory per email (survives leaving/re-entering in the same run; reset on app restart).
- Entering from Sign In "Resend confirmation email" (AC-19) shows the same screen with the remaining cooldown for that email (button disabled with countdown) or enabled if none/zero.
- Display: `mm:ss` tabular. Disabled button uses disabled style but text stays legible (>= 4.5:1: use onSurface at 60% over disabled fill #E2E8F0 = about 4.9:1; M3 default 38% fails, so override `disabledForegroundColor`). Screen reader: label "Resend email, available in N seconds", updated at start and each 15 s.
- When countdown reaches 0: button animates enabled (150 ms colour fade), label "Resend email".

### States
| State | Visual |
|---|---|
| Initial (arrived from sign-up) | Cooldown running at 60 s; no banner. Optional first-arrival hint is the body text itself. |
| Loading (resend in flight) | Button spinner (`buttonLoading`), "Back to sign in" stays enabled. Cooldown not yet started. |
| Success (AC-08) | Success banner "Confirmation email sent" (successIn), cooldown restarts at 60 s; banner auto-dismisses after 5 s (fade 150 ms) and remains in the live region once announced. |
| Failure: rate limit/network/other (AC-11) | Error banner with section 6 text; cooldown NOT restarted (button returns to its prior state: enabled if the cooldown had expired). |
| Link expired/invalid variant (AC-13) | See below. |

### Confirmation-link landing (AC-12, AC-13)
Requirements restrict unauthenticated routes to `/sign-in`, `/sign-up`, `/check-email`, so no extra routes are added; the deep-link outcome is shown on existing screens:

1. **Link confirmed (AC-12):** app navigates to Sign In with the success banner described in section 2 ("Email confirmed. You can now sign in."). Developer note: even if Supabase returns a session through the deep link, the app must not treat it as signed-in for routing (per OQ-01 answer) , confirm with QA.
2. **Link invalid or expired / already used (AC-13):** app navigates to `/check-email` in the **expired variant**:
   - Icon tile uses error colours (`link_off` icon, errorContainer fill, onErrorContainer icon).
   - Title "Link expired" (headlineMedium); error banner (fixed, not auto-dismissed) "This link is invalid or has expired".
   - Body: "Request a new confirmation email below, or go back to sign in."
   - If the pending address is known in this run: shown as in the normal variant and the Resend button works (with cooldown rules). If the address is **not** known (app cold-started by the link): show an `AppTextField` "Email" above the Resend button (same validation as sign-in email); Resend validates then calls resend. After success the screen switches to the normal variant with the address.
   - Actions: `PrimaryButton` (outlined) "Resend email", `TextButton` "Back to sign in".
   - Motion: banner errorIn, icon tile successIn-style scale (300 ms), one `shake` on the banner.

(Owner approved Q-S1: the email field is part of the design. BA is aligning AC-13.)

## 5. Home (`/home`; AC-25, AC-25a/b, AC-26)

### Layout
- `AppBar`: leading `IconButton` hamburger (`menu` icon, 48x48, tooltip/semantics "Open menu"), title "Bakery ERP" (titleLarge, left-aligned next to the icon), bottom 1px border. No actions.
- Body: single widget: the signed-in email, centered horizontally and vertically (`Center`), `dataLarge` (JetBrains Mono Medium 16), onSurface, `textAlign center`, `softWrap` so long emails wrap within 16dp gutters (max width 400); `SelectableText` not required. Nothing else in body (AC-25). Scaffold background #F8FAFC. Semantics: "Signed in as {email}" (visual text is only the email).
- Drawer (`Drawer`, width 304, surface):
  - Header (padding 16, top safe area): email in `dataSmall` secondary (ellipsis at 1 line is acceptable here, full email visible in the body), above it `titleMedium` app name. Divider 1px.
  - `ListTile` "Log out" (leading `logout` icon 24 secondary, label bodyLarge onSurface, min height 48, radius 6, 8dp horizontal margin). It is the only item (AC-25b).
- Open: hamburger tap or edge swipe; close: scrim tap, back, or after Log out (AC-25a). Drawer slide uses Material default (about 250 ms).

### States
| State | Visual |
|---|---|
| Initial | Body email fades in (pageIn 300 ms, fade only; no slide to keep it still). |
| Logout loading (AC-26, section 7 table) | Drawer stays open; "Log out" tile shows a 20dp spinner replacing the icon, tile disabled, label unchanged. Duration normally < 1 s. |
| Logout failure (network) | No error is shown (local sign-out still happens per AC-26); drawer closes and app goes to Sign In. |
| Logout success | Drawer closes (default animation), router redirects to Sign In (`go`); back cannot return. |
| Session ended elsewhere (AC-27) | Redirect to Sign In. No "signed out" banner (Owner decision Q-S2). |

## 6. Cross-screen error/success copy table (final)

| Key | Text |
|---|---|
| invalidEmail | Enter a valid email address |
| weakPasswordClient | Password must be at least 8 characters and include a letter and a number |
| passwordMismatch | Passwords do not match |
| passwordRequired | Enter your password |
| invalidCredentials | Incorrect email or password |
| emailNotConfirmed | Please confirm your email before signing in |
| emailExists | An account with this email already exists. Try signing in. |
| weakPasswordServer | Password is too weak. Use at least 8 characters with a letter and a number. |
| rateLimit | Too many attempts. Please wait a moment and try again. |
| network | No connection. Check your internet and try again. |
| signupDisabled | Sign up is currently unavailable. |
| linkExpired | This link is invalid or has expired |
| generic | Something went wrong. Please try again. |
| resendSuccess | Confirmation email sent |
| emailConfirmed (draft, AC-12) | Email confirmed. You can now sign in. |

## 7. Responsive and orientation

- Landscape phone: content scrolls; icon tiles hidden; card padding 16.
- Width >= 600: gutters 24, card max 400 centered, no side panels. Home drawer stays modal.
- Text scale 130%: banners and buttons grow (buttons use `minimumSize` height, not fixed); link rows wrap to two lines.

## 8. Handoff checklist for Developer (T-04 to T-08)

- Build `ColorScheme` explicitly (no `fromSeed`); add `ThemeExtension`s per design-system.md section 5.
- Page code references only theme tokens (`Theme.of(context)`), spacing constants, and shared widgets.
- Animations live in widgets via `flutter_animate`, each <= 400 ms (max total stagger: 160 ms delay + 200 ms = 360 ms); disable when `disableAnimations`.
- Widget tests should cover: validation messages, loading disables inputs, banner dismissal on edit, countdown label, drawer logout item, small-phone overflow (360x640 with a 260dp `viewInsets`).

## 9. Done criteria for this design task

All screens in requirements section 3 are specified with layout, components, states (initial/loading/error/success), validation and shake, and motion; shared widgets and ThemeData mapped; accessibility covered; conflicts resolved or escalated.

## 10. Owner decisions (2026-10-23), all screen-level questions answered

- Q-S1: approved. The expired-link variant of `/check-email` includes an email field when the pending address is unknown (cold start). BA is aligning AC-13.
- Q-S2: no "signed out" banner on Sign In.
- Q-S3: Home app bar title is "Bakery ERP". The app display name elsewhere (drawer header) is "Bakery".
- Q-S4: prefill the email on Sign In after the link only if the link carries it; otherwise empty.
- Design-system-level decisions (fonts, dark palette, contrast, shared widgets): see `design-system.md` section 8.
