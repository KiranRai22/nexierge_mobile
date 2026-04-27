# HotelOps → Nexierge Flutter Conversion Plan

**Source prototype:** https://hotel-ops.lovable.app/
**Target app:** `nexierge` (Flutter, feature-first)
**Author:** Claude
**Date captured:** 2026-04-25
**Doc revision:** 1.0

---

## 0. About this document

This is a top-down conversion plan that walks the source prototype route-by-route and lays out the Flutter implementation strategy under the project's standing rules:

- `docs/00_PROJECT_PRINCIPLES.md` – first principles
- `docs/01_ARCHITECTURE_RULES.md` – feature-first folder layout (`data/domain/presentation`)
- `docs/02_RIVERPOD_GUIDELINES.md` – Riverpod state contract
- `docs/03_CODE_STYLE_GUIDELINES.md` – ≤300 LOC files, ≤150 LOC widgets
- `docs/05_UI_IMPLEMENTATION_RULES.md` – design-token use, no hardcoded colours
- `docs/06_API_AND_REALTIME_RULES.md` – data layer contracts
- `docs/07_STATE_AND_LIFECYCLE_RULES.md` – AutoDispose, copyWith state

Every implementation phase below references these.

### How extraction was done
- Live walk via Chrome MCP automation: navigated each route, captured DOM text + visual state.
- Routes confirmed by URL change; modal/sheet content extracted from the inlined DOM that React leaves in place.
- Screenshots are listed per route below — drop reference images into `docs/hotel-ops-conversion/screenshots/` using the suggested filenames.

### Confidence of conversion
- **High** for Tickets list, Activity feed, Ticket detail, Universal create, Filter sheet, Create-new sheet, Bottom nav, ETA bottom sheet — all observed working in the prototype.
- **Medium** for Catalog and Manual create flows — only the entry tile in the Create-new sheet exists; the destination routes return 404. We will scaffold the screens and mark them `// TODO: catalog/manual flow not yet defined upstream`.
- **Low / unimplemented** for Modules, Profile, Notifications, Search, Dark-mode toggle behaviour — these are present as buttons but do nothing in the prototype. Treated as future scope.

---

## 1. Route map

| # | URL path | Status | Title | Description |
|---|---|---|---|---|
| 1 | `/` | redirect | — | Lovable SPA entry; redirects to `/tickets`. |
| 2 | `/tickets` | live | Tickets dashboard | Department/hotel-scoped ticket list with KPI strip and sub-tabs. |
| 3 | `/tickets/:id` | live | Ticket detail | Single ticket — guest/room context, request items, timing, lifecycle actions. |
| 4 | `/activity` | live | Activity feed | Chronological event log (Today / Yesterday) with type chips. |
| 5 | `/create/universal` | live | Universal request | Quick item-grid + room picker for housekeeping-style asks. |
| 6 | `/create/catalog` | 404 | Catalog (placeholder) | Mentioned in the Create-new sheet but not implemented upstream. |
| 7 | `/create/manual` | 404 | Manual ticket (placeholder) | Same — entry tile exists only. |
| 8 | `/modules` | 404 | Modules tab (placeholder) | Bottom-nav slot, no implementation. |
| 9 | `/profile` | 404 | Profile tab (placeholder) | Bottom-nav slot, no implementation. |

### Inlined sheets / dialogs (no own URL)
- **Create new** (FAB sheet) — Universal | Catalog | Manual chooser.
- **Filter by department** — multi-select sheet, used by Tickets and Activity.
- **Select room** — Recent + All rooms grouped by floor (used inside Universal create).
- **Accept & set ETA** — preset chips + Custom time, used from Ticket detail.

### Cross-cutting chrome
- **Top bar**: avatar (`FA`), dark-mode toggle, notifications bell with unread dot.
- **Pill segmented**: `My Dept` / `All Hotel` + filter icon (Tickets, Activity).
- **Bottom nav**: Tickets · Activity · [+ FAB centered] · Modules · Profile (5 slots, FAB raised).

---

## 2. Per-screen breakdown

> **Reading guide.** Each screen below answers the 10-point spec:
> 1) Title/description · 2) Screenshot reference · 3) Components & layout ·
> 4) Children · 5) Navigation actions · 6) Flutter conversion plan ·
> 7) Files to create/change · 8) Improvements · 9) TODO markers.

---

### 2.1 `/tickets` — Tickets dashboard

**Title:** *Tickets* · **Description:** Operator's home screen. Shows the current ticket pipeline scoped to "My Dept" or "All Hotel", with a 3-up KPI strip, sub-tab segmented control, and grouped sections for Incoming Now / In Progress / Completed Today.

**Screenshot:** `screenshots/01_tickets_dashboard.png`

**Components & layout (top → bottom):**
1. **AppTopBar** (h:56) — circular avatar `FA` (left), `IconButton(Icons.dark_mode_outlined)` and `IconButton(Icons.notifications_outlined)` with red badge dot (right).
2. **ScopeTabs (pill segmented)** — `My Dept` (selected) | `All Hotel` + trailing filter `IconButton`.
3. **GreetingRow** — `Hi, Fola` (left, `bodyLarge`) + `SUN · 1:00 AM` (right, `bodyMedium textSecondary`).
4. **SearchField** — read-only-feel `AppTextField` with leading magnifier, hint `Search ticket, room or guest…`.
5. **KpiStrip (3 cards)** — `Incoming` (lavender), `In Progress` (lavender), `Overdue` (rose tint when count > 0). Each card: bold count + ALL-CAPS label.
6. **SubTabs** — `Incoming · Today · Scheduled · Done` (pill, scrollable if needed).
7. **GroupedTicketList** — `INCOMING NOW · 2`, `IN PROGRESS · 1`, `COMPLETED TODAY · 1`. Section headers ALL-CAPS with count.
8. **TicketCard** — left coloured border (lavender = active, green = done), title (bold), trailing time (`2m ago` / `ETA 3m` / `Done 9:45`), room + dept row with bed icon, type chip (`Universal`), optional status footer (`In progress · Blessing K.`). Done cards strike-through title.
9. **FAB** — large purple `+` raised over bottom nav.
10. **BottomNavBar** — 5 slots: Tickets (active) · Activity · FAB hole · Modules · Profile.

**Children / sub-screens:** Tapping a card → `/tickets/:id`. FAB → Create-new sheet. Filter icon → Filter-by-department sheet. Bottom-nav buttons → routes.

**Navigation actions:**
- Card tap → ticket detail.
- FAB → create-new bottom sheet.
- Filter icon → department filter sheet.
- `My Dept` / `All Hotel` toggle (state only).
- Sub-tab change (state only).
- Notifications/avatar → not implemented upstream.

**Flutter conversion plan:**
- Screen: `lib/features/tickets/presentation/screens/tickets_screen.dart` (composes top bar + scope tabs + KPI + sub-tabs + grouped list).
- State: `tickets_controller.dart` exposes `TicketsUiState { scope, subTab, departmentFilter, isLoading, items }`.
- Repository: `tickets_repository.dart` returns `List<Ticket>`; mock implementation lives behind `MockTicketsRepository`.
- Each section is a `_TicketGroup` (header + ListView of cards). Card lives in its own widget.
- Re-use `AppPrimaryButton`, `AppTextField` from `core/widgets/widget_manager.dart`. Define new `KpiCard`, `ScopeSegmentedTabs`, `SubTabBar`, `TicketCard`.

**Files to create / change:**
- **Create**
  - `lib/features/tickets/domain/models/ticket.dart`
  - `lib/features/tickets/domain/models/ticket_status.dart`
  - `lib/features/tickets/domain/repositories/tickets_repository.dart`
  - `lib/features/tickets/data/repositories/mock_tickets_repository.dart`
  - `lib/features/tickets/presentation/providers/tickets_controller.dart`
  - `lib/features/tickets/presentation/screens/tickets_screen.dart`
  - `lib/features/tickets/presentation/widgets/app_top_bar.dart`
  - `lib/features/tickets/presentation/widgets/scope_segmented_tabs.dart`
  - `lib/features/tickets/presentation/widgets/kpi_strip.dart`
  - `lib/features/tickets/presentation/widgets/sub_tab_bar.dart`
  - `lib/features/tickets/presentation/widgets/ticket_card.dart`
- **Change**
  - `lib/main.dart` — once auth lands, route post-login to `TicketsScreen`.
  - `lib/core/utils/string_manager.dart` — add `tickets*` strings.
  - `lib/core/theme/color_palette.dart` — add `kpiOverdueTint`, `ticketUniversalChip`, `ticketDoneTint`.

**Suggestions for improvement:**
- The KPI cards do not reflow on small phones; clamp text and add `FittedBox`.
- "Sun · 1:00 AM" should localize date/time via `intl`.
- Add pull-to-refresh on the list.
- Sub-tabs should preserve scroll position per tab.

**TODO markers:**
- `// TODO(tickets): wire real repository — currently mock.`
- `// TODO(tickets): notifications icon — pending notifications feature.`
- `// TODO(tickets): search field is non-functional in prototype.`

---

### 2.2 `/tickets/:id` — Ticket detail

**Title:** *Ticket detail* · **Description:** Full record for a single ticket with primary action `Accept & set ETA`, secondary `Change dept` / `Add note`, and a vertical lifecycle stepper.

**Screenshot:** `screenshots/02_ticket_detail.png`, `screenshots/02b_eta_sheet.png`

**Components & layout:**
1. **DetailAppBar** — back arrow, centred `TKT-3042`, kebab menu.
2. **HeaderChips** — `Universal` chip + status text `New · Unassigned`.
3. **TitleBlock** — `Towels, pillow & toiletries`, `Requested 4 minutes ago · front desk`.
4. **InfoCardsRow** (2 cards, expanded): **Room** (208, Floor 2 · Deluxe) and **Guest** (Mr. Bello, Check-out tomorrow). Each tappable (chevron right).
5. **RequestList** — `REQUEST · 3 items`. Each row: rounded-tile icon, title, sub-label (`Bath`/`Standard`/`Complete set`), trailing `×N`.
6. **GuestNoteCallout** — yellow background, speech-bubble icon, label + body.
7. **TimingStepper** — `Created 4 minutes ago · 10:24` (filled), `Accepted —`, `Done —`.
8. **PrimaryAction** — `Accept & set ETA` (full-width purple, trailing arrow icon).
9. **SecondaryActions** — `Change dept` and `Add note` side-by-side outline buttons.
10. **ETA bottom sheet** — preset chips: 10/15/30 min, 1 hour, Later today, Custom time. "Guest will be notified · Ready by 1:40 AM" + `Accept · 15 min` CTA.

**Children:** ETA sheet, Change-dept sheet (reuses department picker), Add-note text input sheet.

**Navigation actions:**
- Back → previous list.
- Kebab → reassign / cancel (TODO upstream).
- Room card → room detail (TODO).
- Guest card → guest detail (TODO).
- Accept & set ETA → ETA sheet → confirms then transitions ticket to In Progress and pops to list.

**Flutter conversion plan:**
- Screen `ticket_detail_screen.dart` consumes `ticketDetailControllerProvider(id)` (family).
- State exposes `Ticket` + `isAccepting`. On confirm, controller calls `acceptTicket(id, eta)` then pops.
- Each block is its own widget under `presentation/widgets/detail/` to keep the screen file <150 LOC.

**Files to create:**
- `lib/features/tickets/presentation/screens/ticket_detail_screen.dart`
- `lib/features/tickets/presentation/providers/ticket_detail_controller.dart`
- `lib/features/tickets/presentation/widgets/detail/header_chips.dart`
- `lib/features/tickets/presentation/widgets/detail/info_cards_row.dart`
- `lib/features/tickets/presentation/widgets/detail/request_list.dart`
- `lib/features/tickets/presentation/widgets/detail/guest_note_callout.dart`
- `lib/features/tickets/presentation/widgets/detail/timing_stepper.dart`
- `lib/features/tickets/presentation/widgets/detail/eta_bottom_sheet.dart`

**Suggestions:**
- Add an `AppBar.scrolledUnderElevation` to surface the title once the user scrolls.
- Surface guest VIP/preferences on the Guest card.
- Custom-time chip should open a wheel time picker, not a free text.
- Stepper should animate timestamp fill-in when state advances.

**TODO markers:**
- `// TODO(tickets): kebab menu actions — reassign/cancel not in prototype.`
- `// TODO(tickets): room/guest tap targets — destinations not defined.`
- `// TODO(tickets): change-dept and add-note sheets — copy them from filter sheet skeleton.`

---

### 2.3 `/activity` — Activity feed

**Title:** *Activity* · **Description:** Reverse-chronological event log of ticket lifecycle changes (created, accepted, marked done, reassigned, notes, overdue, cancelled).

**Screenshot:** `screenshots/03_activity_feed.png`

**Components & layout:**
1. **AppTopBar** (shared).
2. **ScopeSegmentedTabs** (`My Dept` / `All Hotel`) + filter icon.
3. **TypeChipRow** — horizontally scrollable: `All` (selected, dark) · `Created` · `Accepted` · `Done` · `Overdue` · `Cancelled` · `Notes` · `Reassigned`.
4. **DaySections** — `TODAY`, `YESTERDAY` with grouped items.
5. **ActivityRow** — circular tinted avatar (icon depends on type — `+` for created, `✓` for accepted, double-check for done; colour: lavender / green), text rows: bold subject (e.g. *Ticket created: Extra towels*), meta line (`Room 208 · Housekeeping · TKT-3002`), trailing time (`2m ago`).
6. **FAB + BottomNav** (shared).

**Navigation actions:** Type chip filters list. Row tap → ticket detail. Day section headers are static. (FAB and bottom nav per shared chrome.)

**Flutter conversion plan:**
- Screen: `activity_screen.dart` reuses `AppTopBar`, `ScopeSegmentedTabs`.
- New: `ActivityTypeChipBar` (horizontally scrollable single-select), `DaySection`, `ActivityRow`.
- State: `activity_controller.dart` exposes `{ scope, type, items }`. Repository returns `List<ActivityEvent>` ordered desc by timestamp.
- Group by `Today` / `Yesterday` / `Older` using a date-bucketing helper in `core/utils/date_utils.dart`.

**Files to create:**
- `lib/features/activity/domain/models/activity_event.dart`
- `lib/features/activity/domain/repositories/activity_repository.dart`
- `lib/features/activity/data/repositories/mock_activity_repository.dart`
- `lib/features/activity/presentation/providers/activity_controller.dart`
- `lib/features/activity/presentation/screens/activity_screen.dart`
- `lib/features/activity/presentation/widgets/activity_type_chip_bar.dart`
- `lib/features/activity/presentation/widgets/day_section.dart`
- `lib/features/activity/presentation/widgets/activity_row.dart`

**Suggestions:**
- Group by sticky day headers when scrolling (CustomScrollView).
- Tap-and-hold to jump back to relevant ticket.
- Add a "Latest only" auto-refresh pill at the top when new events arrive.

**TODO markers:**
- `// TODO(activity): wire to live event stream once backend lands.`
- `// TODO(activity): infinite scroll / pagination.`

---

### 2.4 `/create/universal` — Universal request

**Title:** *Universal request* · **Description:** Single-screen quick-create for the most common housekeeping items. Pick item → pick room → optional note → submit.

**Screenshot:** `screenshots/04_create_universal.png`, `screenshots/04b_select_room.png`

**Components & layout:**
1. **DetailAppBar** — back arrow, "Universal request" + sub-line "Tap what you need".
2. **ItemGrid (2-col)** — Towels, Pillows, Toiletries, Blanket, Water, Other. Each tile rounded, large icon, label below; selected tile has primary border.
3. **RoomSection** — `ROOM` label, four-chip row: 3 Recent rooms + `Find` chip. Helper text *Recent rooms · tap to select*.
4. **NoteSection** — `NOTE (OPTIONAL)` label, multiline text field (`Add a note for the team…`).
5. **CtaBar** — left helper text (`Pick an item to start`), right `Create` button (disabled until item picked).
6. **Select room sheet** — full-height: Recent (with floor) + All rooms grouped by floor.

**Navigation actions:** Item tile → select. Find chip → opens select-room sheet. Recent chip → preselects room. Create → POST → pop to list.

**Flutter conversion plan:**
- Screen: `universal_create_screen.dart`. Local Riverpod controller `universalCreateController` with state `{ item, roomId, note }` and `canCreate` getter.
- Reuse `AppTextField` for note. Reuse a generic `RoomPickerSheet` (also used by Manual ticket later).
- ItemGrid is its own widget; tile component reusable.

**Files to create:**
- `lib/features/tickets/presentation/screens/universal_create_screen.dart`
- `lib/features/tickets/presentation/providers/universal_create_controller.dart`
- `lib/features/tickets/presentation/widgets/create/item_grid.dart`
- `lib/features/tickets/presentation/widgets/create/item_tile.dart`
- `lib/features/tickets/presentation/widgets/create/recent_rooms_row.dart`
- `lib/features/tickets/presentation/widgets/create/room_picker_sheet.dart`

**Suggestions:**
- Show a subtle confirmation toast on Create with `Undo` (5 s).
- Prefill recent room from device's "last used room" if set.
- Drop the `Other` tile in favour of a "Catalog" CTA once Catalog flow is ready.

**TODO markers:**
- `// TODO(tickets): "Other" tile destination — currently unspecified.`
- `// TODO(tickets): rooms list source — backend endpoint TBD.`

---

### 2.5 `/create/catalog` — Catalog (placeholder)

**Title:** *Catalog* · **Description:** Intended room-service / spa / bar order flow. Upstream prototype shows a 404; we will scaffold a screen that says "Coming soon" so navigation works without dead ends.

**Screenshot:** none — placeholder.

**Components & layout:** Centered illustration + headline + sub + back button.

**Files to create:**
- `lib/features/tickets/presentation/screens/catalog_create_screen.dart` (stub)

**TODO markers:**
- `// TODO(tickets): catalog flow not yet defined upstream.`

---

### 2.6 `/create/manual` — Manual ticket (placeholder)

**Title:** *Manual ticket* · **Description:** Free-form complaint/issue ticket. Upstream prototype is also 404.

**Files to create:**
- `lib/features/tickets/presentation/screens/manual_create_screen.dart` (stub)

**TODO markers:**
- `// TODO(tickets): manual ticket fields — define with PM.`

---

### 2.7 Modules / Profile (placeholders)

Both bottom-nav slots are non-functional upstream. We still implement the bottom-nav buttons but show placeholder screens that read "Coming soon" so the pixel layout matches.

**Files to create:**
- `lib/features/modules/presentation/screens/modules_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`

**TODO markers:**
- `// TODO(modules): scope and contents pending PM definition.`
- `// TODO(profile): profile contents pending — settings, theme, sign-out, language.`

---

### 2.8 Inline sheets (no own URL)

#### Create-new sheet (FAB)
- Trigger: FAB tap from any tab.
- Content: title `Create new`, subtitle `What kind of ticket are you creating?`, three rows (Universal / Catalog / Manual) each with leading icon + title + description, footer hint *Not sure? Manual works for anything.*
- File: `lib/features/tickets/presentation/widgets/create_new_sheet.dart`.

#### Filter-by-department sheet
- Trigger: filter icon on Tickets and Activity.
- Content: title + count text + Select all + 6 departments + Clear / Apply.
- File: `lib/features/tickets/presentation/widgets/filter_department_sheet.dart` (or move to `core/widgets` if reused outside tickets).

---

## 3. Theme & design tokens

| Token | Value (observed) | Notes |
|---|---|---|
| `primary` | `#7B5CFF` (purple) | FAB, CTAs, active tab text |
| `primaryTint` | `#EFE8FF` | Universal chip, lavender card backgrounds |
| `green / done` | `#21B26A` | Done card stripe, accepted activity |
| `overdueRose` | `#FBE7EB` | Overdue KPI tint |
| `noteYellow` | `#FFF7CC` | Guest-note callout |
| `text/primary` | `#0E1116` | Titles |
| `text/secondary` | `#6B7180` | Meta, sub-labels |
| Card radius | 16 | All cards/sheets |
| Sheet handle | 4 × 28, 50% on-surface | Top of every bottom sheet |
| Spacing scale | 4 / 8 / 16 / 24 | Per `05_UI_IMPLEMENTATION_RULES.md` |
| Font | Figtree (variable) → fallback to project's existing font | Configure in `theme_manager.dart` |

These get added to `core/theme/color_palette.dart` and `core/theme/typography_manager.dart`. **No widget should hardcode colours** — all consumed through these managers.

---

## 4. Files inventory (all phases)

### Create
```
lib/features/tickets/
  domain/
    models/ticket.dart
    models/ticket_status.dart
    models/ticket_request_item.dart
    repositories/tickets_repository.dart
  data/
    repositories/mock_tickets_repository.dart
  presentation/
    providers/tickets_controller.dart
    providers/ticket_detail_controller.dart
    providers/universal_create_controller.dart
    screens/tickets_screen.dart
    screens/ticket_detail_screen.dart
    screens/universal_create_screen.dart
    screens/catalog_create_screen.dart
    screens/manual_create_screen.dart
    widgets/app_top_bar.dart
    widgets/scope_segmented_tabs.dart
    widgets/kpi_strip.dart
    widgets/sub_tab_bar.dart
    widgets/ticket_card.dart
    widgets/create_new_sheet.dart
    widgets/filter_department_sheet.dart
    widgets/detail/header_chips.dart
    widgets/detail/info_cards_row.dart
    widgets/detail/request_list.dart
    widgets/detail/guest_note_callout.dart
    widgets/detail/timing_stepper.dart
    widgets/detail/eta_bottom_sheet.dart
    widgets/create/item_grid.dart
    widgets/create/item_tile.dart
    widgets/create/recent_rooms_row.dart
    widgets/create/room_picker_sheet.dart
lib/features/activity/
  domain/models/activity_event.dart
  domain/repositories/activity_repository.dart
  data/repositories/mock_activity_repository.dart
  presentation/providers/activity_controller.dart
  presentation/screens/activity_screen.dart
  presentation/widgets/activity_type_chip_bar.dart
  presentation/widgets/day_section.dart
  presentation/widgets/activity_row.dart
lib/features/modules/presentation/screens/modules_screen.dart
lib/features/profile/presentation/screens/profile_screen.dart
lib/features/shell/presentation/screens/home_shell.dart   # Bottom nav host
lib/features/shell/presentation/widgets/app_bottom_nav.dart
lib/core/router/app_router.dart                          # Centralised navigation
lib/core/utils/date_utils.dart                           # `Today / Yesterday` bucketing
```

### Modify
```
lib/main.dart                                # Post-login route → HomeShell
lib/core/theme/color_palette.dart            # New tokens (Universal chip, KPI tints, etc.)
lib/core/theme/typography_manager.dart       # Add headline/title sizes for KPI cards
lib/core/utils/string_manager.dart           # tickets/activity/create strings
lib/core/widgets/widget_manager.dart         # Optionally re-export new shared bits (chip, segmented)
pubspec.yaml                                 # Add go_router (or stay manual), intl
```

### Probably unchanged
```
lib/features/auth/**
lib/features/notifications/**
lib/core/error/**
lib/core/network/**
```

---

## 5. Architecture notes (project-rule alignment)

- **Feature-first**: `tickets`, `activity`, `modules`, `profile`, `shell` each own their `data/domain/presentation`. Cross-cutting bits (top bar, bottom nav, segmented tabs, theme) live in `core` or `features/shell`.
- **Riverpod (`02_RIVERPOD_GUIDELINES.md`)**: every controller is `AutoDisposeNotifier<T>`; state is immutable with `copyWith`; UI does `ref.watch(provider)` for state and `ref.read(provider.notifier)` for actions.
- **Code style (`03_CODE_STYLE_GUIDELINES.md`)**: file ≤ 300 LOC, widget ≤ 150 LOC. Extract any block over budget.
- **UI rules (`05_UI_IMPLEMENTATION_RULES.md`)**: spacing 4/8/16/24; no hardcoded colours; portrait-only; keyboard avoidance via `SingleChildScrollView` + `resizeToAvoidBottomInset: true` (already enforced on the Login screen pattern).
- **State/lifecycle (`07_STATE_AND_LIFECYCLE_RULES.md`)**: text controllers disposed in `dispose()`; routes pop via `Navigator.of(context).pop()`; auto-dispose providers default unless we hit a documented reason not to.

---

## 6. Improvements over the prototype

| # | Improvement | Where |
|---|---|---|
| 1 | True deep linking with named routes (`/tickets/:id`, etc.) | `core/router/app_router.dart` (introduce `go_router`). |
| 2 | Pull-to-refresh on Tickets and Activity | `RefreshIndicator` wrap. |
| 3 | Empty states for each section (icon + headline + sub) | `tickets_screen.dart`, `activity_screen.dart`. |
| 4 | Skeleton loaders on first load (shimmer) | `kpi_strip.dart`, `ticket_card.dart`. |
| 5 | Snackbar toast with `Undo` after Create | `universal_create_screen.dart`. |
| 6 | Localised time strings (`intl`) | `core/utils/date_utils.dart`. |
| 7 | Accessibility — `Semantics` labels on icons-only buttons | All icon buttons. |
| 8 | Theme switch wires through `ThemeMode` provider | `core/theme/theme_manager.dart`. |
| 9 | Dynamic text size respect (`MediaQuery.textScaler`) | KPI / card titles use `FittedBox` + `maxLines`. |
| 10 | Offline-first — repositories cache last list | `data/repositories/*` + Hive/Isar later. |

---

## 7. Phased delivery plan

The plan splits work into **incremental phases**. Each phase is a complete vertical slice that compiles and runs. Mock data is used until the API contract is finalised (per `06_API_AND_REALTIME_RULES.md`).

### Phase 0 — Foundation (theme + shell + navigation)
- Add design tokens (colours, typography sizes for KPI/section headers).
- `HomeShell` with `BottomNavigationBar` + raised FAB.
- `core/router/app_router.dart` with named routes.
- Empty placeholder screens for Tickets / Activity / Modules / Profile.

**Acceptance:** App runs, bottom nav navigates between four placeholder screens, FAB shows a "TODO" toast. **Output ≤ 8 small files.**

### Phase 1 — Tickets dashboard (read-only)
- Domain models + mock repository (4 sample tickets covering Universal / Catalog / Manual, 3 statuses).
- `TicketsController` exposes filtered list.
- `TicketsScreen` with KPI strip, scope tabs, sub-tabs, grouped sections, ticket card.
- Filter-by-department sheet (state-only).

**Acceptance:** Pixel match with `screenshots/01_tickets_dashboard.png` ± 4 px; sub-tabs filter mock list.

### Phase 2 — Ticket detail + Accept/ETA
- `TicketDetailScreen` reads via family provider.
- ETA bottom sheet — preset chips + custom time wheel.
- `acceptTicket` action mutates mock repo and routes back; KPI strip updates.

**Acceptance:** Tap a card → detail → Accept → returns to list, item moves to In Progress section.

### Phase 3 — Activity feed
- `ActivityRepository` + mock data sourced from ticket events.
- Type chip filtering, day grouping, row tap → ticket detail.

**Acceptance:** Activity list reflects Phase 2 actions (creating/accepting writes events).

### Phase 4 — Universal create
- Item grid, recent rooms row, room picker sheet, note field.
- Submitting creates a ticket in the mock repo (which feeds back into Phases 1–3).

**Acceptance:** FAB → Create-new sheet → Universal → fill in → Create → back at list with new card on top.

### Phase 5 — Catalog & Manual stubs
- Scaffold both screens with "Coming soon" content.
- Wire Create-new sheet rows to navigate.

**Acceptance:** Each row in Create-new sheet navigates to a styled placeholder.

### Phase 6 — Polishing & a11y
- Pull-to-refresh, empty states, skeletons.
- Theme toggle wired (light/dark).
- Snackbars with Undo.
- Semantics labels.
- Localised time via `intl`.

**Acceptance:** App passes the rules in `08_TESTING_AND_REVIEW.md` and all `code-style-guidelines` budgets.

### Phase 7 — Real backend integration
- Replace mock repos with real implementations.
- Realtime updates per `06_API_AND_REALTIME_RULES.md`.
- Push notifications already in place — link `tap` to deep link `/tickets/:id`.

**Acceptance:** App functional against real API; old mock repos remain behind a feature flag for offline demos.

---

## 8. Phase-wise prompts (copy-paste into Claude)

> Use these prompts in order. Each one assumes the prior phases are merged. Do not run them in parallel.

### Prompt — Phase 0
```
Implement Phase 0 of docs/hotel-ops-conversion/HOTEL_OPS_CONVERSION_PLAN.md.

Scope:
1. Add the new design tokens listed in section 3 to lib/core/theme/color_palette.dart and lib/core/theme/typography_manager.dart. No hardcoded colours anywhere else.
2. Create lib/features/shell/presentation/screens/home_shell.dart hosting a BottomNavigationBar with 5 slots (Tickets, Activity, FAB hole, Modules, Profile) and a centered raised FAB. Match the prototype layout — see section 1 "Cross-cutting chrome".
3. Create lib/core/router/app_router.dart using a simple Navigator with named routes for /tickets, /tickets/:id, /activity, /create/universal, /modules, /profile. Use go_router only if it's already in pubspec; otherwise plain Navigator with onGenerateRoute is fine.
4. Add empty placeholder screens for Tickets, Activity, Modules, Profile — each shows a centered title.
5. Update lib/main.dart so the post-login destination becomes HomeShell. (LoginScreen flow is unchanged.)

Constraints from docs:
- File ≤ 300 LOC, widget ≤ 150 LOC.
- AutoDispose Riverpod where state is needed.
- Spacing scale 4/8/16/24, no hardcoded colours.
- Portrait only — preserve the existing portrait lock in main.dart.

Deliver: a tree of new files, the touched main.dart diff, and a screenshot from a flutter run on iPhone 15 Pro showing the empty bottom nav working.
```

### Prompt — Phase 1
```
Implement Phase 1 of docs/hotel-ops-conversion/HOTEL_OPS_CONVERSION_PLAN.md (Tickets dashboard, read-only).

Scope:
1. Domain models (Ticket, TicketStatus, RequestItem) and a TicketsRepository abstract.
2. MockTicketsRepository returning 4 sample tickets covering Universal / Catalog / Manual and three statuses (incoming, in progress, completed today).
3. TicketsController (AutoDisposeNotifier) — state: { scope, subTab, departmentFilter, isLoading, items }. Computes KPI counts from items.
4. TicketsScreen composes: AppTopBar, ScopeSegmentedTabs, GreetingRow, SearchField (read-only for now), KpiStrip (3 cards), SubTabBar, GroupedTicketList with TicketCard.
5. FilterDepartmentSheet (state-only) — opened from the filter icon in ScopeSegmentedTabs.
6. Pixel match section 2.1 of the plan and the prototype screenshot screenshots/01_tickets_dashboard.png ± 4 px.

Reuse from core: AppTextField, AppPrimaryButton (if used), ColorPalette, TypographyManager, StringManager.
Add new strings to string_manager.dart instead of hardcoding.

Constraints: Section 5 "Architecture notes" — re-read before starting.

Deliver: tree of new files, run + screenshot proof.
```

### Prompt — Phase 2
```
Implement Phase 2 (ticket detail + accept/ETA).

Scope:
1. TicketDetailScreen at /tickets/:id consuming ticketDetailControllerProvider.family(id).
2. Sub-widgets in widgets/detail/: header_chips, info_cards_row (Room | Guest), request_list, guest_note_callout, timing_stepper.
3. PrimaryAction "Accept & set ETA" opens the ETA bottom sheet (sub-widget eta_bottom_sheet.dart) with preset chips 10/15/30 min, 1 hour, Later today, Custom time + "Accept · 15 min" CTA.
4. acceptTicket(id, eta) mutates the mock repo, advances status, then pops back to the list.
5. Match section 2.2 of the plan, ± 4 px against screenshots/02_ticket_detail.png and screenshots/02b_eta_sheet.png.

Constraints: file ≤ 300 LOC, widget ≤ 150 LOC. AutoDispose. Localise time via intl.

Deliver: tree of new files + a recording (or 3 screenshots) showing tap-card → detail → accept → back-to-list with new state.
```

### Prompt — Phase 3
```
Implement Phase 3 (Activity feed).

Scope:
1. Domain ActivityEvent + ActivityRepository.
2. MockActivityRepository derives events from the mock TicketsRepository (created/accepted/done/note/cancel/reassign/overdue).
3. ActivityController exposes { scope, type, items } and exposes today / yesterday / older buckets.
4. ActivityScreen composes shared chrome + ActivityTypeChipBar + DaySection + ActivityRow. Row tap → /tickets/:id.

Match section 2.3 of the plan, ± 4 px against screenshots/03_activity_feed.png.

Deliver: new files + screenshot.
```

### Prompt — Phase 4
```
Implement Phase 4 (Universal create).

Scope:
1. universal_create_screen.dart with item grid, recent rooms row, RoomPickerSheet, note field, Create CTA disabled until item picked.
2. universalCreateController state { item, roomId, note }; canCreate getter.
3. On Create: write a Ticket into MockTicketsRepository (which Activity repo also reads from), pop, snackbar with Undo (5 s).

Match section 2.4 of the plan, ± 4 px against screenshots/04_create_universal.png and screenshots/04b_select_room.png.

Deliver: new files + screenshots showing create + new card visible at the top of the Tickets list.
```

### Prompt — Phase 5
```
Stub out Catalog and Manual create flows.

Scope:
1. catalog_create_screen.dart and manual_create_screen.dart — each shows back arrow, illustration placeholder, headline ("Catalog" / "Manual ticket"), sub ("Coming soon") and a return-to-tickets button.
2. Wire CreateNewSheet rows to navigate to these screens.
3. No state, no repository changes.

Deliver: new files + recording showing all three Create-new rows navigating.
```

### Prompt — Phase 6
```
Polish pass.

Scope:
1. RefreshIndicator on Tickets and Activity.
2. Empty states (icon + headline + sub) per section when list is empty.
3. Shimmer skeletons on KPI strip and ticket card while isLoading.
4. Theme toggle (light/dark) wired through a ThemeMode AutoDisposeNotifierProvider; persist via shared_preferences if available, else in-memory.
5. Semantics labels for all icon-only buttons.
6. Localised time strings via intl. Replace any "2m ago" hardcoding.
7. Re-run all docs/code-style budgets — refactor anything over file/widget LOC limits.

Deliver: diff summary + screenshots: light/dark, empty states, shimmer.
```

### Prompt — Phase 7
```
Replace mock repositories with real implementations.

Scope:
1. Implement TicketsRepository / ActivityRepository against the live API per docs/06_API_AND_REALTIME_RULES.md.
2. Add realtime updates (web socket / SSE) for ticket events; Activity feed reflects them live.
3. Wire FCM tap → deep link /tickets/:id (notifications service already in place).
4. Keep mocks behind a debug feature flag for offline demos.

Constraints: backwards-compatible interfaces — UI screens must not change.

Deliver: integration test suite + run against staging.
```

---

## 9. Conversion fidelity & limitations

- The prototype is a **Lovable React SPA**; some interactions are placeholders (Modules, Profile, Notifications, Catalog, Manual). Their final UX must come from the PM before Phase 5/7.
- Animation/transition curves are not extracted from the prototype — defaults from Material 3 will be used and refined in Phase 6.
- Typography uses *Figtree* in the prototype. We will fall back to the project's existing font unless the PM specifies adopting Figtree.
- The "search" field is decorative in the prototype; we will mark it `// TODO` until search semantics are agreed.
- Times like "Sun · 1:00 AM" appear baked-in upstream; in Flutter we will compute live via `DateTime.now()` and `intl`.

---

## 10. Open questions for PM

1. Final shape of Catalog and Manual create flows (Phase 5 today is a stub).
2. Modules tab — which modules ship in v1?
3. Profile tab — what fields/actions live there (sign-out, theme, language, version, support)?
4. Notifications inbox UX — sheet vs full screen?
5. Search semantics — full-text? scoped? saved filters?
6. Offline behaviour — read-only cache or full create-then-sync?
7. Auth — current Login screen flow integrates how with HomeShell entry?

---

*End of plan v1.0 — capture refreshed 2026-04-25 from https://hotel-ops.lovable.app/*
