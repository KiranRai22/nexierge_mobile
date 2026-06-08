# Theme Consolidation — Analysis & Migration Plan

> **STATUS: ✅ COMPLETE.** All 7 steps landed. `lib/` is free of `Color(0x…)`,
> `Colors.<x>` (except `Colors.transparent`), and `ColorPalette.<x>` outside
> `lib/core/theme/`. `flutter analyze lib/` passes with 0 errors.
> `scripts/check_no_hardcoded_colors.sh` returns clean. Legacy
> `color_palette.dart` and `unified_theme_manager.dart` are deleted.


> **Goal:** One source of truth for color in this app. Every screen, every widget,
> every future enhancement reads color from the theme — never from a palette
> constant, never from a hardcoded `Color(0xFF…)`, never from `Colors.xxx`.

---

## 1. Where We Are Today

Three (really four) styling systems coexist in `lib/` and constantly fight each other:

| # | System | Where | Refs | Theme-aware? |
|---|--------|-------|------|--------------|
| 1 | **AppColors `ThemeExtension`** (modern, canonical) | `lib/core/theme/app_colors.dart` (+ `context.appColors`) | **~218** | ✅ Full light + dark |
| 2 | **`ColorPalette` static constants** (legacy) | `lib/core/theme/color_palette.dart` | **~621** | ❌ Single hex per token |
| 3 | **Hardcoded `Color(0xFF…)`** in widgets | scattered (75+ refs in 11 files) | **~75** | ❌ Manual `isDark` checks |
| 4 | **Material `Colors.xxx`** (white/black/grey…) | scattered | **~144** | ❌ Not themed |

> Plus: `UnifiedThemeManager` exists but is **dead code** — it duplicates `AppColors`,
> doesn't build the real `ThemeData` used by `main.dart`, and adds a redundant
> `context.themeColors` alias that nobody calls. It must be deleted.

### 1.1 Theme infra inventory (`lib/core/theme/`)

| File | Status | Purpose |
|------|--------|---------|
| `app_colors.dart` | ✅ Keep — canonical | `ThemeExtension<AppColors>` with ~90 semantic tokens, light + dark constants, `context.appColors` getter, `CardDecoration` helpers. |
| `theme_manager.dart` | ✅ Keep — **now the entry point** (swapped in by Step 2). Builds `ThemeData` for light/dark; installs `AppColors`, `AppRadii`, `AppShadows`; wires `appBarTheme`, `dialogTheme`, `snackBarTheme`, `inputDecorationTheme`, `textTheme`, etc. all from `AppColors`. |
| `theme_mode_controller.dart` | ✅ Keep | Riverpod controller for `ThemeMode` (system/light/dark) with `SharedPreferences` persistence under `app.themeMode`. |
| `typography_manager.dart` | ✅ Keep | `TextStyle` constants (non-color). |
| `app_radii.dart` | ✅ Keep | Border radius tokens. |
| `app_shadows.dart` | ✅ Keep | Shadow tokens (light/dark). |
| `card_theme.dart` | ✅ Keep | `CardDecoration` helpers reading from `AppColors`. |
| `unified_theme_manager.dart` | 🟡 **Now a back-compat shim** (Step 2 done). Reduced to `export 'app_colors.dart';` + `@Deprecated`. ~65 widget files still import it; each emits an `info` lint nudging migration. Delete the file once every import has been moved (Step 6). |
| `color_palette.dart` | 🗑 **Deprecate then delete** | 174 hex constants, no dark variant. Migrate refs → `AppColors`, then remove. |

### 1.2 Conflict examples (same semantic, different hex)

| Semantic | `ColorPalette` | `AppColors.light` | Problem |
|----------|---------------|-------------------|---------|
| Primary brand | `0xFFE91E63` (pink) | `bgInteractive 0xFF3B82F6` (blue) | Buttons render pink; new screens expect blue/purple. |
| Error | `0xFFEA4335` | `fgError 0xFFE11D48` | Two reds claim to be "the" error red. |
| Success | `0xFF34A853` | _missing_ | Token gap — toasts hardcode it. |
| HotelOps purple | `opsPurple 0xFF7B5CFF` | _missing_ | Ticket UI leans on `ColorPalette`. |

### 1.3 Worst-offender files (single-file mixing of all 3 systems)

| File | `ColorPalette` | `Color(0x…)` | `Colors.xxx` | `context.appColors` |
|------|---:|---:|---:|---:|
| `features/tickets/.../create_screen_catalog.dart` | 110 | — | — | 0 |
| `features/tickets/.../create_screen_universal.dart` | 64 | 5 | 2 | 3 |
| `shared/widgets/app_toast.dart` | 0 | 36 | 2 | 0 |
| `features/tickets/.../catalog_customizer_sheet.dart` | 42 | 6 | — | 0 |
| `features/tickets/.../ticket_card_compact.dart` | 39 | — | — | 2 |
| `features/tickets/.../ticket_card.dart` | 30 | — | several | 0 |
| `features/auth/.../login_top_toast.dart` | — | 12 | — | 0 |
| `shared/widgets/shimmer_widget.dart` | — | 5 | — | 0 |

### 1.4 Architectural smells

- **Dark mode is leaky.** Hardcoded hex colors don't flip with `ThemeMode`. Toasts and shimmers re-implement `isDark` locally instead of letting the theme handle it.
- **No semantic tokens for status/feedback.** Success/warning/info aren't in `AppColors`, so every consumer invents its own.
- **Material `ColorScheme` is half-wired.** `primary = ColorPalette.primary` (legacy pink); buttons inherit the wrong brand.
- **Two BuildContext extensions** (`appColors` + `themeColors`) — pick one.

---

## 2. Other Approaches You Could Use (Considered & Rejected)

| Approach | Verdict | Why |
|----------|---------|-----|
| **Per-feature static color classes** (e.g. `TicketColors`, `AuthColors`) | ❌ Reject | Reproduces the current mess at a smaller scale. Hard to keep consistent across features. |
| **Multiple `ThemeExtension`s (one per domain)** | ⚠️ Use sparingly | OK *only* when a domain has many tokens nobody else needs (e.g. a charting library). Default to one `AppColors`. |
| **Design-tokens generated from JSON / Figma Tokens** | 🔭 Future option | Worth it once design and engineering agree on a token spec. Not now — `AppColors` is already in code. |
| **Pure `ColorScheme` (Material3) only** | ❌ Reject | M3 scheme is too small (~13 slots) for a product app. We need 90+ semantic tokens. |
| **Riverpod-provided color theme** | ❌ Reject | `ThemeData` + `ThemeExtension` already give us reactive theming via `MaterialApp.themeMode`. Adding Riverpod on top is redundant. |

**Chosen approach:** `AppColors` (`ThemeExtension`) is the single source of truth, exposed exclusively through `context.appColors.*`. The Material `ColorScheme` is derived from it.

---

## 3. The Target State

```
                         ┌──────────────────────────┐
                         │   AppColors (Extension)  │
                         │   • light + dark consts  │
                         │   • ~100 semantic tokens │
                         └──────────┬───────────────┘
                                    │
                                    ▼
                         ┌──────────────────────────┐
                         │      ThemeManager        │
                         │  build ThemeData {       │
                         │    colorScheme: derived  │
                         │    extensions: [AppColors,│
                         │                 AppRadii, │
                         │                 AppShadows]│
                         │  }                       │
                         └──────────┬───────────────┘
                                    │
                                    ▼
            MaterialApp(theme: light, darkTheme: dark, themeMode: …)
                                    │
                                    ▼
            Every widget → context.appColors.xxx   (ONLY route)
```

Rules at the leaf:

- **No** `Color(0xFF…)` literals in widgets.
- **No** `Colors.white` / `Colors.black` / `Colors.red` in widgets.
- **No** `ColorPalette.xxx` references in new code.
- Reading: `context.appColors.fgPrimary`, `context.appColors.bgSurface`, etc.
- Decorations: prefer `CardDecoration.standard(context.appColors)` over rebuilding.

---

## 4. Step-by-Step Migration Plan

A sequential, low-risk path. Each step is independently mergeable.

### Step 0 — Lock the rule (DONE)
- ✅ Rule saved to memory (`feedback_theme_single_source.md`) and indexed.
- ✅ This analysis doc lives at `docs/THEME_CONSOLIDATION_PLAN.md`.

### Step 2 — Reduce `UnifiedThemeManager` to a shim, promote `ThemeManager` (DONE)
> Note: order shifted — Step 2 was executed before Step 1 because the audit had the file roles backwards (`UnifiedThemeManager` was actually live, not dead) and the wiring had to be corrected before anything else.
- ✅ `main.dart` now imports `theme_manager.dart` and uses `ThemeManager.lightTheme` / `ThemeManager.darkTheme`. This brings in the proper `appBarTheme`, `dialogTheme`, `snackBarTheme`, `bottomSheetTheme`, `inputDecorationTheme`, `textTheme`, `iconTheme`, `dividerTheme`, `listTileTheme`, `progressIndicatorTheme`, `bottomNavigationBarTheme`, `navigationBarTheme`, `outlinedButtonTheme`, `textButtonTheme` — all derived from `AppColors`, so they flip on dark mode.
- ✅ `context.themeColors` getter moved into `app_colors.dart` (alongside `context.appColors`); now a thin alias.
- ✅ `unified_theme_manager.dart` collapsed to `export 'app_colors.dart';` with `@Deprecated`. The dead `UnifiedThemeManager` class, `_ThemeColors`, `_LightColors`, `_DarkColors` are gone.
- ✅ `flutter analyze` — 0 errors. ~60 `deprecated_member_use_from_same_package` info lints flag the imports that still need to migrate to `app_colors.dart` (each one is a single-line edit).

**Expected visual differences (now using `ThemeManager`):**
- ✅ Fix: Dark-mode app bar title was hardcoded `Color(0xFF18181B)` in the old file → effectively invisible on dark surfaces. Now reads `colors.fgBase` so it flips correctly.
- ✅ Fix: Material widgets that previously fell back to Flutter defaults (dialogs, snackbars, list tiles, default text styles, input decoration, divider color, bottom nav, navigation rail, progress indicators) now follow `AppColors` and flip cleanly on dark mode.
- ⚠️ Tooltip / `inverseSurface` shade is very slightly darker in light mode (`0xFF18181B` vs old `0xFF27272A`). Imperceptible in practice.
- ⚠️ Default `OutlinedButton` and `TextField` now use themed colors; if any screen relied on Flutter defaults, it'll look slightly different — but every screen we've seen already wires its own decoration, so unlikely to bite.

### Step 1 — Make `AppColors` semantically complete
Add the missing tokens that today force hardcoded hex:
- `fgSuccess`, `bgSuccess`, `bgSuccessSubtle`, `borderSuccess`
- `fgWarning`, `bgWarning`, `bgWarningSubtle`, `borderWarning`
- `fgInfo`, `bgInfo`, `bgInfoSubtle`, `borderInfo`
- `fgError` already exists → add `bgError`, `bgErrorSubtle`, `borderError`
- `shimmerBase`, `shimmerHighlight`
- `toastShadow`, `toastBorderDefault`
- `brandPrimary`, `brandSecondary`, `brandAccent` (replace `ColorPalette.primary/secondary/accent`)
- `opsPurple` and the `ticketStripe*`, `status*`, `activity*` tokens (port from `ColorPalette`)
- `loginPrimary`, `loginAccent`, etc. (port from `ColorPalette` login block)

Every token gets a light AND dark value. No exceptions.

### Step 2 — Delete `UnifiedThemeManager`
- Remove `lib/core/theme/unified_theme_manager.dart`.
- Remove its imports and the unused `context.themeColors` extension. `context.appColors` is the one extension.

### Step 3 — Wire `ColorScheme` from `AppColors`
In `theme_manager.dart`, derive `ColorScheme` slots from `AppColors` instead of `ColorPalette.primary`. Light:
```dart
colorScheme: ColorScheme.light(
  primary:   AppColors.light.brandPrimary,
  secondary: AppColors.light.brandSecondary,
  error:     AppColors.light.fgError,
  surface:   AppColors.light.bgSurface,
  onPrimary: AppColors.light.fgOnBrand,
  // …
),
```
Same for dark. This single change fixes most `ElevatedButton` / `SnackBar` / `Dialog` colors automatically.

### Step 4 — Migrate the high-frequency primitives FIRST
Touching these widgets gives the biggest win per LOC. Migrate in this order — each is one PR:

1. **`shared/widgets/app_toast.dart`** (36 hardcoded). Replace ToastType palette with `context.appColors.{bg,fg,border}{Success|Error|Warning|Info}`.
2. **`shared/widgets/shimmer_widget.dart`** (5 hardcoded). Use `shimmerBase` / `shimmerHighlight`.
3. **`features/auth/.../login_top_toast.dart`** (12 hardcoded). Same toast tokens as #1.
4. **`features/tickets/.../ticket_card_compact.dart`** + **`ticket_card.dart`** (39 + 30 palette). Swap to `appColors`.
5. **`features/tickets/.../create_screen_catalog.dart`** (110 palette) — biggest single file; split into ≥2 PRs.
6. **`features/tickets/.../create_screen_universal.dart`** (64 palette + 5 hex + 2 `Colors.`).
7. **`features/tickets/.../catalog_customizer_sheet.dart`** (42 palette + 6 hex).
8. Sweep the long tail (notifications, profile, dashboard).

For each PR:
- Replace `ColorPalette.X` → `context.appColors.Y` (add `Y` in Step 1 if missing).
- Replace `Color(0x…)` → `context.appColors.Y` or add token in Step 1.
- Replace `Colors.white/black/grey` → `context.appColors.bgSurface` / `fgPrimary` / `border` (semantic match — don't blindly remap).
- Verify dark mode visually for every screen touched.

### Step 5 — Lint the regressions out
Add a custom lint or grep-based CI check (`scripts/check_no_hardcoded_colors.sh`) that fails the build if `lib/` contains:
- `Color(0x` outside `lib/core/theme/`
- `Colors\.` (excluding `Colors.transparent`) outside `lib/core/theme/`
- `ColorPalette\.` (after Step 6)

Run it in pre-commit and CI.

### Step 6 — Delete `color_palette.dart`
Once Step 4 hits zero references, delete the file. Update `pubspec.yaml` / barrel exports. Done.

### Step 7 — Document the contract
Add a short "Theming" section to `docs/05_UI_IMPLEMENTATION_RULES.md`:
- The rule (see §5 below).
- Snippet of correct usage.
- How to add a new token (PR `app_colors.dart` first, then use it).

---

## 5. The Rule (Non-negotiable, going forward)

> **"Always register new color to theme. When creating a component, always use the color from the theme."**

Operational form:

1. **Never** introduce `Color(0xFF…)`, `Colors.xxx` (except `Colors.transparent`), or new entries in `ColorPalette` in a widget.
2. If the shade you need doesn't exist in `AppColors`, **add it there first** — light + dark — then consume via `context.appColors.<name>`.
3. Naming is semantic, not visual: `bgSuccessSubtle`, not `lightGreen50`.
4. Every PR that adds/modifies a widget must be greppable as zero new `Color(0x` / `Colors\.` / `ColorPalette\.` introductions.
5. Reviewers reject PRs that violate this. No exceptions for "quick fixes".

---

## 6. Effort Estimate

| Step | Effort | Risk |
|------|--------|------|
| 0  Doc + rule + memory | 0.5h | None |
| 1  Extend `AppColors` (tokens + dark variants) | 3–4h | Low |
| 2  Delete `UnifiedThemeManager` | 0.5h | Low |
| 3  Wire `ColorScheme` from `AppColors` | 1–2h | Medium (visual regressions) |
| 4  Migrate widgets (8 PRs) | 12–18h | Medium |
| 5  Add CI lint | 1h | None |
| 6  Delete `ColorPalette` | 0.5h | Low |
| 7  Doc update | 0.5h | None |
| **Total** | **~20–28h** | |

---

## 7. Quick-Reference: Token Map (initial draft)

| Old (`ColorPalette` / hex) | New (`context.appColors.*`) |
|---|---|
| `ColorPalette.primary` (0xFFE91E63) | `brandPrimary` |
| `ColorPalette.secondary` | `brandSecondary` |
| `ColorPalette.error` / `0xFFEA4335` | `fgError` / `bgError` |
| `ColorPalette.success` / `0xFF34A853` | `fgSuccess` / `bgSuccess` |
| `ColorPalette.warning` | `fgWarning` / `bgWarning` |
| `ColorPalette.info` | `fgInfo` / `bgInfo` |
| `ColorPalette.opsPurple` (0xFF7B5CFF) | `opsPurple` |
| `Colors.white` (as surface) | `bgSurface` |
| `Colors.black` (as text) | `fgPrimary` |
| `Colors.black.withValues(alpha: …)` (shadow) | `AppShadows.*` via `context.appShadows` |
| `Color(0xFFE0E0E0)` (shimmer base) | `shimmerBase` |
| `Color(0xFFF5F5F5)` (shimmer highlight) | `shimmerHighlight` |

Extend this table as you migrate.
