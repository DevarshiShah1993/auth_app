# Design System: "Modern Bakery SaaS" (Sprint 01 / T-02)

_Owner of this file: Designer. Status: Approved by Owner (Gate 2), decisions of 2026-10-23 applied. Source: Owner-supplied design system (2026-10-23), `CLAUDE.md`, `docs/requirements/sprint-01-email-auth.md`. No requirement is changed here._

Vibe: clean, minimal, data-dense, professional. Material 3, one `ThemeData` in `core/theme`, light + dark. Pages never hardcode colors or text styles (CLAUDE.md).

## 1. Conflicts and resolutions

Contrast figures are WCAG 2.x ratios (computed from sRGB relative luminance).

| # | Conflict | Finding | Resolution |
|---|---|---|---|
| C-1 | White text on Primary #D97706 | 3.2:1, fails 4.5:1 for normal text | Button label / icon on primary fill uses **#0F172A** (5.6:1). Brand colour stays #D97706 exactly. `onPrimary = #0F172A`. |
| C-2 | Primary #D97706 as text/link on #F8FAFC / #FFFFFF | about 3.1:1, fails for text | Add token `primaryText = #B45309` (5.0:1 on white, 4.8:1 on background) for links and text-style actions. #D97706 itself is used only for fills, the focus ring (3:1 non-text OK) and progress indicators. |
| C-3 | Danger #EF4444 as small text | 3.8:1, fails | Fills/icons/borders use #EF4444. Error **text** uses `dangerText = #B91C1C` (6.5:1). |
| C-4 | Success #10B981 as small text | about 2.5:1, fails | Fills/icons use #10B981. Success **text** uses `successText = #047857` (5.5:1). |
| C-5 | Input border #E2E8F0 (1px) is 1.2:1 against surface; WCAG 1.4.11 wants 3:1 for UI component boundaries | Fails for inputs | #E2E8F0 stays for **cards/dividers** as specified. Idle **input** outline uses `inputBorder = #64748B` (4.8:1). Focus = 2px #D97706 ring as specified. |
| C-6 | High density vs 48dp touch targets | Dense 32-36dp controls fail Material/WCAG 2.5.8 comfort target | Visual density stays tight (8px grid, 6px radius, 8/16 gaps), but every tappable control has a **min 48x48dp hit area**. Buttons and fields are 48dp tall. Density is expressed through typography size/spacing, not shrinking targets. `VisualDensity.standard` (no compact). |
| C-7 | "Minimal shadow on cards" vs "buttons flat, no shadows" vs M3 elevation tint | M3 adds surface tint/elevation by default | `surfaceTintColor: transparent`, `elevation: 0` on buttons, app bar, drawer. Only cards get the 0 1px 2px rgba(0,0,0,0.05) shadow (via `BoxDecoration`, not elevation). In dark mode the shadow is dropped (invisible) and the 1px border carries separation. |
| C-8 | Design system lists #F8FAFC as the only background; CLAUDE.md requires light + dark | Dark palette not supplied | Derived dark palette in section 3 (same hue family, slate-based, amber primary lightened). Needs Owner approval (see questions). |
| C-9 | Inter / JetBrains Mono need a font source | CLAUDE.md: do not swap stack without asking | **Owner decision (Q-1):** bundle Inter (400/500/600) and JetBrains Mono (400/500) as `.ttf` assets in `assets/fonts/` declared under `pubspec.yaml` `fonts:`, with their SIL OFL licence files alongside (`assets/fonts/licenses/`). No `google_fonts` package. System font remains the fallback. |
| C-10 | Tight tracking on headings vs readability | Negative tracking hurts small text | Tracking applies only to headings >= 20sp (-0.02em). Body keeps 0 tracking. |
| C-11 | App display name | Supabase project is spelled "Backary" | **Owner decision (Q-4):** display name is "Bakery" (used in the drawer header and window/app title). The Home app bar title is "Bakery ERP" (Q-S3). |

## 2. Design tokens (light)

### 2.1 Colors

| Token | Hex | Use | Flutter mapping |
|---|---|---|---|
| primary | #D97706 | Button fill, focus ring, progress | `ColorScheme.primary` |
| onPrimary | #0F172A | Text/icon on primary (C-1) | `ColorScheme.onPrimary` |
| primaryContainer | #FEF3C7 | Soft highlight (success/info banners, selected drawer item) | `primaryContainer` |
| onPrimaryContainer | #78350F | Text on primaryContainer (9.0:1) | `onPrimaryContainer` |
| primaryText | #B45309 | Links, text buttons (C-2) | `ThemeExtension AppColors.primaryText`; also `TextButtonThemeData` foreground |
| secondary | #475569 | Secondary text, icons, outlined button | `ColorScheme.secondary` |
| onSecondary | #FFFFFF | on secondary (7.6:1) | `onSecondary` |
| background | #F8FAFC | Scaffold | `ColorScheme.surface` is #FFFFFF; scaffold uses `scaffoldBackgroundColor = #F8FAFC` (see 5.1) |
| surface | #FFFFFF | Cards, drawer, app bar, input fill | `ColorScheme.surface`, `surfaceContainerLowest` |
| onSurface | #0F172A | Primary text (17.8:1 on white) | `onSurface` |
| onSurfaceVariant | #475569 | Helper text, labels, icons | `onSurfaceVariant` |
| outlineVariant | #E2E8F0 | Card/divider borders | `outlineVariant` |
| outline | #64748B | Input idle border (C-5) | `outline` |
| error | #EF4444 | Error border, icon | `ColorScheme.error` |
| onError | #FFFFFF | (rarely used; 3.8:1, large/icon only) | `onError` |
| errorContainer | #FEF2F2 | Error banner fill | `errorContainer` |
| onErrorContainer | #B91C1C | Error banner text (6.5:1; 5.9:1 on container) | `onErrorContainer` |
| success | #10B981 | Success icon/border | `AppColors.success` (ThemeExtension) |
| successContainer | #ECFDF5 | Success banner fill | `AppColors.successContainer` |
| successText | #047857 | Success text (5.5:1; 5.2:1 on container) | `AppColors.successText` |
| scrim | #0F172A at 40% | Drawer scrim | `ColorScheme.scrim` |
| disabled content | onSurface at 38% | Disabled text | M3 default |
| disabled fill | #E2E8F0 | Disabled button fill | via `ButtonStyle.backgroundColor` WidgetState.disabled |

Remaining M3 roles (`tertiary*`, `surfaceContainer*`, `inverseSurface`, etc.) must be explicitly set so M3 does not derive off-palette tints: tertiary = secondary values; `surfaceContainer`, `surfaceContainerHigh` = #FFFFFF; `surfaceContainerLow` = #F8FAFC; `inverseSurface` = #0F172A, `onInverseSurface` = #F8FAFC (SnackBar). Build the scheme with `ColorScheme(...)` explicitly (not `fromSeed`).

### 2.2 Typography

Families: `Inter` (UI), `JetBrains Mono` (data). Fallback: platform system font. Weights: Regular 400, Medium 500, SemiBold 600. Numbers (countdown, email read-only data) use tabular figures: `FontFeature.tabularFigures()`.

| TextTheme slot | Family / weight | Size / line height | Tracking | Used for |
|---|---|---|---|---|
| headlineMedium | Inter SemiBold | 28 / 36 | -0.02em (-0.56) | Auth screen title |
| titleLarge | Inter SemiBold | 22 / 28 | -0.02em (-0.44) | App bar title, check-email heading |
| titleMedium | Inter SemiBold | 16 / 24 | 0 | Drawer header, banner title |
| bodyLarge | Inter Regular | 16 / 24 | 0 | Input text, button-adjacent copy |
| bodyMedium | Inter Regular | 14 / 20 | 0 | Body copy, helper/error text, banners |
| bodySmall | Inter Regular | 12 / 16 | 0.01em | Fine print (never < 12) |
| labelLarge | Inter SemiBold | 14 / 20 | 0.01em | Buttons, links |
| labelMedium | Inter Medium | 12 / 16 | 0.02em | Field floating label (when raised) |
| (extension) dataLarge | JetBrains Mono Medium | 16 / 24 | 0 | Home centered email |
| (extension) dataSmall | JetBrains Mono Regular, tabular | 14 / 20 | 0 | Countdown "00:42", target email on Check-email |

`dataLarge`/`dataSmall` live in a `ThemeExtension<AppTextStyles>`. Text scale: layouts must survive textScaler up to 1.3 (scroll, no clipped text, no fixed-height containers for text).

### 2.3 Geometry and spacing

- Grid: 8px base. Spacing scale (`AppSpacing`): 4 (half-step, icon gaps only), 8, 16, 24, 32, 48.
- Radius: 6 everywhere (buttons, inputs, cards, banners, drawer item shape). Drawer container itself has radius 0 (full height). Exception: none.
- Border: 1px `outlineVariant` on cards/banners-neutral; banners use 1px of their semantic colour at 40% over container.
- Card shadow: `BoxShadow(offset 0,1; blur 2; color 0x0D000000)` (rgba(0,0,0,0.05)). Light only.
- Page gutter: 16dp (compact), 24dp when width >= 600. Max content width: 400dp, centered (so tablets/landscape stay tidy).
- Control height: 48dp (buttons, inputs, list tiles). Icon size 24 (20 inside inputs' suffix, with 48dp hit area).

## 3. Dark palette (derived)

Same hue family (slate neutrals, amber accent). Contrast ratios shown against the token's usual backing.

| Token | Hex | Notes |
|---|---|---|
| primary | #F59E0B | Amber 500: lifted so fills stay vivid on dark; onPrimary #0F172A = 8.7:1 |
| onPrimary | #0F172A | |
| primaryContainer | #451A03 | |
| onPrimaryContainer | #FDE68A | 11:1 |
| primaryText | #FBBF24 | links; 10:1 on surface |
| secondary | #94A3B8 | |
| onSecondary | #0F172A | |
| scaffold background | #0B1220 | |
| surface | #111A2B | cards, app bar, drawer |
| surfaceContainerHigh | #162033 | menus/dialogs |
| onSurface | #F1F5F9 | 15:1 |
| onSurfaceVariant | #A8B5C7 | 7.6:1 |
| outlineVariant | #263449 | card/divider border |
| outline (input idle) | #7B8BA3 | 4.6:1 vs surface |
| error | #F87171 | |
| onError | #450A0A | |
| errorContainer | #3F1212 | |
| onErrorContainer | #FCA5A5 | 7.9:1 |
| success | #34D399 | |
| successContainer | #0B2F24 | |
| successText | #6EE7B7 | 10:1 |
| scrim | #000000 at 60% | |
| disabled fill | #1E293B | |

Focus ring in dark: 2px #F59E0B. Card shadow removed (border only).

## 4. Motion tokens (flutter_animate)

All effects < 400 ms, `Curves.easeOutCubic` unless stated. No animation logic in Blocs; widgets only. Honor reduce-motion: when `MediaQuery.disableAnimations` is true, skip all effects (render final state; shake is replaced by the error text appearing).

| Name | Spec | Duration |
|---|---|---|
| pageIn | `fadeIn` + `slideY(begin: 0.04 (about 8-16dp), end: 0)` on the main content column | 300 ms |
| staggerIn | Children of the content column get pageIn with `delay: index * 40ms` (max 5 children, so last starts at 160 ms; last ends <= 360 ms with 200 ms effect) | 200 ms each |
| shake | `shakeX(hz: 4, amount: 6)` on the invalid field / form card, triggered once per failed validation or failed submit | 320 ms |
| errorIn | Error text / banner: `fadeIn` + `slideY(begin: -0.1)` | 200 ms |
| buttonLoading | `AnimatedSwitcher` between label and 20dp spinner (cross-fade + scale 0.9 to 1); button width/height unchanged | 200 ms |
| successIn | Success icon: `scale(begin: 0.8)` + `fadeIn` | 300 ms |

## 5. ThemeData mapping (spec for T-04; no code written here)

### 5.1 ThemeData

- `useMaterial3: true`; `colorScheme`: explicit per sections 2 and 3; `brightness` set accordingly.
- `scaffoldBackgroundColor`: #F8FAFC light / #0B1220 dark (differs from `colorScheme.surface`, intentional).
- `textTheme`: section 2.2, color `onSurface`. `fontFamily: 'Inter'`.
- `visualDensity: VisualDensity.standard`; `materialTapTargetSize: MaterialTapTargetSize.padded`.
- `splashFactory: InkRipple.splashFactory` or `NoSplash` is not allowed (ripple feedback kept for accessibility); highlight colour primary at 12%.
- `dividerTheme`: 1px `outlineVariant`, space 1.
- `extensions`: `AppColors` (primaryText, success, successContainer, successText, cardShadow), `AppTextStyles` (dataLarge, dataSmall), `AppSpacing`.

### 5.2 Component themes

| Theme | Spec |
|---|---|
| `AppBarTheme` | `backgroundColor` surface, `elevation 0`, `scrolledUnderElevation 0`, `surfaceTintColor` transparent, `centerTitle: false`, `titleTextStyle` titleLarge, bottom 1px `outlineVariant` border (via `shape: Border(bottom: ...)`), `iconTheme` onSurface 24, toolbar height 56 |
| `DrawerTheme` | `backgroundColor` surface, `elevation 0`, `surfaceTintColor` transparent, `scrimColor` scrim, `width 304`, `shape` right edge 1px `outlineVariant` border, radius 0 |
| `ListTileTheme` (drawer items) | `minVerticalPadding 8`, `minTileHeight 48`, `shape` RoundedRectangle 6, `selectedTileColor` primaryContainer, `iconColor` secondary, `textColor` onSurface |
| `InputDecorationTheme` | `filled: true`, `fillColor` surface; `isDense: false`, `contentPadding` horizontal 16 vertical 14 (gives 48dp height with 16/24 text); `border`/`enabledBorder`: `OutlineInputBorder(borderRadius 6, BorderSide(color: outline, width 1))`; `focusedBorder`: width **2**, color primary (the "2px primary ring"; to avoid layout jump, content padding is the same and the extra 1px grows outward only via `Container` ring or accept the 1px internal shift of 1dp: use `focusedBorder` width 2 and `enabledBorder` width 1 and add 0.5dp compensation is unnecessary, Flutter outlines paint centered so no reflow); `errorBorder`: 1px error; `focusedErrorBorder`: 2px error; `disabledBorder`: 1px outlineVariant with disabled fill; `labelStyle` bodyLarge onSurfaceVariant; `floatingLabelStyle` labelMedium (colour primaryText when focused, dangerText when error); `hintStyle` bodyLarge onSurfaceVariant at 70%; `helperStyle`/`errorStyle` bodyMedium (error colour = `onErrorContainer`/dangerText); `errorMaxLines 3`; `prefixIconColor`/`suffixIconColor` secondary; `floatingLabelBehavior: auto` |
| `FilledButtonTheme` (primary action) | `backgroundColor` primary, `foregroundColor` onPrimary, `elevation 0`, `shadowColor` transparent, `surfaceTintColor` transparent, `minimumSize Size(double.infinity, 48)` (in forms; Size(64,48) otherwise), `padding` horizontal 16, `shape` RoundedRectangle 6, `textStyle` labelLarge; disabled: bg `disabled fill`, fg onSurface 38%; pressed overlay onPrimary 12%; focus overlay onPrimary 16% + 2px `onSurface` outline ring (keyboard focus visibility) |
| `OutlinedButtonTheme` | fg onSurface, `side` 1px outline (#64748B), 6 radius, min 48, no elevation |
| `TextButtonTheme` | fg `primaryText`, `minimumSize Size(48,48)`, `tapTargetSize padded`, 6 radius, labelLarge, no underline by default; focus: 2px primary outline |
| `CardTheme` | `color` surface, `elevation 0`, `shadowColor` transparent, `surfaceTintColor` transparent, `shape` RoundedRectangle 6 with 1px `outlineVariant`, `margin` zero; the 0 1px 2px shadow is applied by the `AppCard` decoration (not in scope as a shared widget; used by Sign In/Up form card, see screens spec) |
| `SnackBarTheme` | `behavior floating`, `backgroundColor` inverseSurface, 6 radius, `contentTextStyle` bodyMedium onInverseSurface, `elevation 0`, margin 16 |
| `ProgressIndicatorTheme` | `color` primary, `circularTrackColor` transparent; button spinner 20dp stroke 2 using colour `onPrimary` |
| `IconButtonTheme` | min 48x48, icon 24, colour onSurface, focus ring 2px primary |
| `DividerTheme` | see above |
| `PageTransitionsTheme` | default per platform (no custom transitions; keeps motion under budget) |

Bakery-themed brand elements, illustrations, or imagery: none this sprint (clean/minimal). A single leading icon (Material Symbols outlined, 24-32dp, in a 48-56dp tile with `primaryContainer` fill and 6 radius) is the only decorative element.

## 6. Shared widgets (in `core/widgets`)

### 6.1 AppTextField
- Wraps `TextFormField`; props: `label`, `controller`, `focusNode`, `keyboardType`, `textInputAction`, `autofillHints`, `errorText`/validator, `enabled`, `onChanged`, `onFieldSubmitted`, `prefixIcon?`, `suffix?`, `autovalidate on blur` handled by the parent form using focus listeners (requirement: validate on submit and on blur, clear error on edit).
- Visible label above the field is **not** used; M3 floating label inside the outline (saves vertical space on small phones). The label must remain readable when raised (labelMedium 12sp).
- Height 48dp idle; grows by error line (bodyMedium 14/20, reserved space is NOT pre-allocated, so the form shifts down by 20-24dp on error: animate with `AnimatedSize` 150 ms to avoid a jump).
- States: idle (1px outline), hover (web/desktop: border onSurface), focused (2px primary ring), error (1px error; 2px when focused; error text below with leading `error_outline` 16dp icon so error is not colour-only), disabled (during loading: fill disabled, text 38%), filled.
- Semantics: label is the accessible name; error text announced via `Semantics(liveRegion: true)`.
- Shake: wrapper applies `shake` when its error transitions null -> non-null on submit.
- Email field: `keyboardType: emailAddress`, `autofillHints: [email]`, `autocorrect false`, `enableSuggestions false`, `textInputAction: next`, `textCapitalization none`.

### 6.2 PasswordField
- Extends AppTextField behaviour; `obscureText` true by default; suffix `IconButton` (48x48 hit target, 20dp icon `visibility` / `visibility_off`), tooltip + semantics label "Show password" / "Hide password".
- Visibility resets to hidden when the screen is left (state is widget-local, disposed with the page; AC-06). Also reset to hidden when app goes to background (nice to have, optional).
- `autofillHints`: `password` (sign in), `newPassword` (sign up, both fields), `enableSuggestions false`, `autocorrect false`, `keyboardType visiblePassword` not used (use `text`, to keep password-manager behaviour).
- Sign-up password field shows persistent helper text "At least 8 characters, with a letter and a number" (bodyMedium, onSurfaceVariant), replaced by the error when invalid. Confirm field has no helper.

### 6.3 PrimaryButton
- Wraps `FilledButton` with theme from 5.2. Props: `label`, `onPressed`, `isLoading`, optional `icon`.
- `isLoading`: button stays enabled-looking (primary fill, not greyed), `onPressed` ignored (no double submit), label swapped to a 20dp spinner (colour onPrimary, stroke 2) via `buttonLoading`; semantics label "Loading" / `Semantics(label: '$label, loading')`, `liveRegion`. Size never changes.
- Full width, 48dp height. Also provide a `SecondaryButton`-style variant using `OutlinedButton` for "Resend email" (disabled during cooldown). (Not named in CLAUDE.md shared-widget list; allowed as `PrimaryButton(variant: outlined)` to keep one class. Developer's choice; noted in Q-5.)

### 6.4 Supporting (small, used by screens)
- `InlineBanner` (in `core/widgets`): variants error / success / info; container fill + 1px border at 40% + leading icon 20dp + bodyMedium text + optional trailing text action. `Semantics(liveRegion: true)`. 6 radius, padding 12 horizontal 16... uses 8-grid: padding 16 h, 12 v is a 4-multiple; permitted half-step.
- `AuthScaffold` layout wrapper (scroll view, gutter, max width 400, keyboard handling, SafeArea).

## 7. Accessibility

- Contrast: all text >= 4.5:1, large text/icons/focus ring/borders of inputs >= 3:1 (verified in sections 1-3). Re-check any new colour pairing before use.
- Never rely on colour alone: errors have icon + text; success has icon + text; input error also changes ring width.
- Touch targets: >= 48x48dp for all buttons, links (TextButton padded), icon buttons, drawer items, password toggle. Spacing between adjacent targets >= 8dp.
- Focus: visible 2px primary focus ring on fields; on buttons/links/icon buttons a 2px outline (primary for outlined/text, onSurface for the filled primary button because primary-on-primary is invisible). Logical tab order top to bottom: email, password, (confirm), submit, secondary link. `textInputAction.next` moves focus, last field `done` submits. On validation failure focus moves to the first invalid field.
- Screen readers: every field labelled; errors announced (live region); loading announced; countdown announced at start and every 15 s only (not each second), via a separate semantics label ("Resend available in 45 seconds") while the visual timer ticks each second with `ExcludeSemantics`.
- Text scaling to 130% without clipping; layouts scroll. Respect `disableAnimations`.
- Language: sentence case, plain, no jargon; errors say what to do next.
- Dark and light must both meet the same ratios; system theme mode default (`ThemeMode.system`).
- Keyboard (web/desktop/hardware): Enter submits, Esc closes drawer, drawer focus trap while open.

## 8. Owner decisions (2026-10-23), all open questions answered

- Q-1 Fonts: bundle Inter (400/500/600) and JetBrains Mono (400/500) in `assets/fonts` with licence files; no `google_fonts`. Answered.
- Q-2 Derived dark palette (section 3): approved.
- Q-3 Contrast deviations C-1..C-5: approved.
- Q-4 App display name: "Bakery".
- Q-5 `InlineBanner`, `AuthScaffold` and the outlined `PrimaryButton` variant: approved as shared widgets in `core/widgets`.
