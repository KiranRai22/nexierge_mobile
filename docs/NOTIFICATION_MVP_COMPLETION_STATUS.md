# Notification MVP — Completion Status & Gap Analysis

**Date:** 2026-06-02
**Scope:** Inspection of the mobile Notification feature against the MVP spec ("Mobile Notification System — Complete MVP Documentation"). No code was modified during this review.

---

## 1. Executive Summary

The notification system has a **solid technical foundation** (FCM push, in-app inbox sheet, websocket realtime sync, optimistic read/unread, deep linking) but is currently **ticket-centric only**. Of the eight notification source domains described in the MVP (Inbox, Tickets, Universal Requests, Paid Services, Guests/Rooms, ARIA, mentions, escalations), **only Tickets is wired end-to-end**.

The single most consequential gap is that **FCM tokens are not registered with the backend** — the registration call is a stub. Without it, push notifications cannot be reliably targeted to the device, which undermines the "drive operational action fast" promise of the MVP.

| Area | Status |
|------|--------|
| FCM infrastructure (foreground/background/terminated) | ✅ Done |
| Token registration to backend | ❌ STUB |
| In-app notification center (sheet, tabs, infinite scroll) | ✅ Done |
| Read / unread state + optimistic UI | ✅ Done |
| Realtime cross-device sync (websocket) | ✅ Done |
| Deep linking | ⚠️ Partial (ticket only) |
| Ticket events | ✅ Done |
| Inbox / Universal Requests / Paid Services / Guests / ARIA events | ❌ Not modeled |
| Department / permission routing on client | ⚠️ Delegated to server, not validated client-side |
| Priority visual treatment (Informational / Action / Urgent) | ⚠️ Modeled, not visually differentiated |
| Notification badge on app icons / tabs | ❌ Missing |
| Bulk mark-read endpoint | ❌ Missing (loops per item) |

---

## 2. What Has Been Built (Included in Current Build)

### 2.1 Architecture & Files
Feature lives at [lib/features/notifications](lib/features/notifications) and follows the project's Clean Architecture rules (`data/`, `domain/`, `presentation/`).

Key files:
- [notification_service.dart](lib/core/services/notification_service.dart) — FCM + flutter_local_notifications
- [notification_remote_datasource.dart](lib/features/notifications/data/datasources/notification_remote_datasource.dart)
- [notification_inbox_datasource.dart](lib/features/notifications/data/datasources/notification_inbox_datasource.dart)
- [notification_ticket_dto.dart](lib/features/notifications/data/dtos/notification_ticket_dto.dart)
- [notification_inbox_item.dart](lib/features/notifications/domain/entities/notification_inbox_item.dart)
- [notification_inbox_controller.dart](lib/features/notifications/presentation/providers/notification_inbox_controller.dart)
- [notifications_sheet.dart](lib/features/notifications/presentation/widgets/notifications_sheet.dart)
- [notification_card.dart](lib/features/notifications/presentation/widgets/notification_card.dart)
- [xano_notification_channel.dart](lib/core/services/realtime/xano_notification_channel.dart) — realtime hub join + event routing
- [xano_socket_service.dart](lib/core/services/realtime/xano_socket_service.dart) — websocket transport

### 2.2 Push Notifications (FCM)
- Initialized in [main.dart:48](lib/main.dart:48). Token fetched and cached in SharedPreferences at startup.
- Foreground messages handled via `FirebaseMessaging.onMessage`; displayed via `flutter_local_notifications` with a custom channel `high_importance_channel_v2`.
- Background handler is registered as a top-level function and renders the local notification.
- Terminated-state launch handled via `getInitialMessage()`.
- Tap routing surfaced through a `ValueNotifier<RemoteMessage?> onNotificationTap` that the UI layer observes.
- Custom sound: `android/app/src/main/res/raw/notification_sound.mp3` and `ios/Runner/notification_sound.caf`.
- Locale-aware FCM topics (`loc_en` / `loc_es`) are synchronized via `syncLocaleTopic()`.
- L10n key allow-list lets the backend send `{l10nTitleKey, l10nArg}` payloads instead of pre-localized strings.

### 2.3 In-App Notification Center
A bottom-sheet UI ([notifications_sheet.dart](lib/features/notifications/presentation/widgets/notifications_sheet.dart)) opened from the Dashboard bell and the Tickets screen.

Implemented behaviors:
- Draggable sheet (60 % → 95 %).
- Two tabs: **Unread** (with badge, capped at 99+) and **Read**.
- Info banner with retention messaging ("Unread auto-cleared after 72 h", "Read auto-cleared after 48 h", with "Clear all" action).
- Pull-to-refresh and infinite scroll (loads next page at 80 % scroll).
- Skeleton shimmer placeholders during initial load and load-more.
- Empty state and error state (with retry).

### 2.4 Notification Model
`NotificationInboxItem` carries:
`id`, `kind` (enum), `priority` (`informational | actionRequired | urgent`, derived from `final_severity` 1–5), `title`, `subtitle`, `receivedAt`, `unread`, `groupHexColor`, `ticketId`, `routeHint`.

Type mapping currently supports:
`ticket_created`, `ticket_assigned`, `ticket_overdue`, `ticket_escalated`, `ticket_completed`, `other`.

### 2.5 Read / Unread Lifecycle
- Field `unread` derived from server `is_read` / `status` (`emitted_and_unread` vs `emitted_and_read`).
- Optimistic local update on tap; fire-and-forget POST to `notifications/mark-read`.
- `markAllAsRead()` loops the visible unread items (no bulk endpoint yet).
- `clearAllRead()` POSTs to `notifications/tickets/clear-read`.
- Cross-device sync: when another session marks read, a `notification_read` websocket frame triggers `refresh()`.

### 2.6 Realtime Sync
- Raw WebSocket to Xano (`xano_socket_service.dart`) with exponential backoff (max 10 s) and message queuing while connecting.
- Two channels joined:
  - `liveTickets/{hotelId}` — ticket entity stream.
  - `hub_notifications/{hotelId}/{ticketHubTicketId}` — notification stream; `ticketHubTicketId` is the `hub_preset_id` from `hub_access` where `hub_code == 'tickets'`. Joined immediately after `auth/me` by `dashboard_bootstrap_controller`.
- Events handled: `notification_created` → `refreshUnreadCount()`; `notification_read` → full `refresh()`.

### 2.7 Deep Linking
Tap on a card → mark read → if `ticketId != null`, close sheet and call `onOpenTicket(ticketId)`. Hosting screens push `TicketDetailScreen`. Server's `route_hint` is read but only `ticket_detail` is acted upon.

### 2.8 API Endpoints in Use
| Endpoint | Method | Path |
|---|---|---|
| Fetch list | GET | `/mobile/notifications/tickets` |
| Mark one read | POST | `/notifications/mark-read` |
| Clear all read | POST | `/mobile/notifications/tickets/clear-read` |
| Register FCM token | POST | **STUB — not defined in `APIEndpoints`** |

### 2.9 Riverpod State
Providers: `notificationServiceProvider`, `notificationNotifierProvider`, `notificationInboxControllerProvider`, `notificationInboxDatasourceProvider`, `xanoNotificationChannelProvider`, `xanoHubNotificationsListenerProvider`.
`NotificationInboxState` tracks `items`, `isLoading`, `isLoadingMore`, `hasMore`, `offset`, `statusFilter`, `totalUnreadCount`, `error`.

### 2.10 Localization
All inbox and push strings are in `app_en.arb` / `app_es.arb` (e.g. `notificationsTitle`, `notificationsInfoUnread`, `notifNewTicket`). FCM payload l10n-key allow-list lives in `notification_service.dart`.

---

## 3. What Has Changed vs. the MVP Spec

These items were either consciously simplified or implemented differently from the MVP wording:

1. **Inbox naming.** The MVP uses "All / Unread" tabs. The implementation uses **"Unread / Read"** tabs and adds a 72 h / 48 h retention banner — a stricter, anti-clutter model than the spec.
2. **Mark-all-read** is implemented as a client-side loop over visible unread items rather than a single `read-all` server call. The MVP spec lists `POST /notifications/read-all` — that endpoint is **not present**.
3. **Notification states** in the spec are `UNREAD / READ / ARCHIVED (future)`. The implementation models only `unread: bool` + server status; archive concept is absent.
4. **Notification grouping.** The MVP mentions "basic notification grouping" — the current sheet shows a flat chronological list. A `groupHexColor` is stored on each item but used only as an accent strip, not as a grouping mechanism.
5. **Realtime events.** Spec lists `notification.created`, `notification.updated`, `notification.read`. The implementation handles `notification_created` and `notification_read`. There is **no `notification_updated` handler**.
6. **Priority indicator.** `priority` is computed (`informational / actionRequired / urgent`) but is **not visually differentiated** in `notification_card.dart` (no color/icon swap based on severity).
7. **Department routing** is fully delegated to the server. The client does not assert that an incoming notification matches the user's department before showing it.

---

## 4. What Is Not Yet Done (Gaps vs. MVP)

### 4.1 Critical (Blocking MVP)
1. **FCM token registration to backend is a stub.** `NotificationRemoteDataSource.registerToken()` does nothing. Until this is wired, push delivery cannot be reliably targeted per user / device. Requires a defined `APIEndpoints.registerFcmToken` + POST body (`user_id`, `push_token`, `platform`, `app_version`).
2. **Token refresh listener is missing.** No subscription to `FirebaseMessaging.instance.onTokenRefresh`. A rotated token will not be re-uploaded.
3. **Only ticket events are modeled.** All other MVP sources have **no DTO, no inbox row, no deep link**:
   - Inbox events (new WhatsApp / OTA / IG message, conversation assigned, mention/tag)
   - Universal Requests (new request, request overdue)
   - Paid Services (new order, cancelled, delayed)
   - Guests & Rooms (VIP check-in, complaint-risk arrival, emergency room move)
   - ARIA signals (complaint risk, repeated unresolved issue)

### 4.2 Important (User-Visible Gaps)
4. **No notification badge** on app icon / tab bar / bell. The unread count exists in state but is rendered only inside the sheet header.
5. **Priority visual treatment.** `urgent` notifications look identical to `informational` ones in the list.
6. **Deep-link router is hardcoded** to `ticket_detail`. Adding any new event type requires a code change instead of a route-hint switch.
7. **No "Mentions" / "Assigned to me" / "Urgent" filter tabs** (called out as optional in the spec but absent).
8. **No iOS notification permission prompt UX** beyond the default Firebase request. No re-request flow or settings deep-link if the user denied.

### 4.3 Robustness
9. **No bulk `read-all` endpoint** — N+1 requests on "Mark all read".
10. **`notification_updated` event** not implemented — server-side edits to an existing notification won't reflect.
11. **Realtime reconnect strategy** does not pair with a reconcile-on-reconnect fetch for notifications (the controller relies on the next user action to refresh). Per the user's standing preference (`feedback_realtime_sync_strategy.md`), every realtime feature should pair with reconcile-on-reconnect + on-resume.
12. **No `WidgetsBindingObserver` resume-fetch** — opening the app from background does not trigger a notification refresh.
13. **`mark-read` failures are silent** (fire-and-forget). A stale unread state can persist across sessions if the server call fails.
14. **No telemetry / analytics** on tap-through, time-to-action, or per-event-type interaction (which the MVP says is the KPI).

### 4.4 Anti-Spam Hygiene (per the MVP's "uncomfortable truth")
15. **No client-side suppression** of low-value events (e.g., minor state pings). Today the client trusts the server completely; if the server emits noisy events, the inbox will degrade.
16. **No quiet-hours, digest, or rate-limit logic** (acknowledged as out-of-scope for MVP, but worth noting for the post-MVP roadmap).

---

## 5. Execution Plan — Closing the Gaps

The plan is sequenced so that each step unlocks the next, with the most operationally-critical work first.

### Phase 1 — Make Push Actually Work (1–2 days)
**Goal:** A push sent to a specific user reaches their device.
1. Define `APIEndpoints.registerFcmToken` (POST `/mobile/devices/register`, body: `user_id`, `push_token`, `platform`, `app_version`, `locale`).
2. Implement `NotificationRemoteDataSource.registerToken()` to call it. Add idempotency by sending only when token changes vs. cached value.
3. Subscribe to `FirebaseMessaging.instance.onTokenRefresh` in `NotificationService` and re-register.
4. Register / re-register on app launch, on login, and on logout (delete-token endpoint).
5. Add a simple `notification_delivery_log` debug screen (gated) to confirm token + last delivery — only used during QA.

**Verification:** Send a test push from the backend tool to a known `user_id`, confirm receipt on a physical device in foreground, background, and terminated states.

### Phase 2 — Generalize the Inbox Beyond Tickets (3–5 days)
**Goal:** Non-ticket events render correctly and deep-link to the right screen.
1. Extend `NotificationKind` enum to add: `inboxMessage`, `inboxMention`, `conversationAssigned`, `universalRequestCreated`, `universalRequestOverdue`, `paidServiceOrderCreated`, `paidServiceOrderCancelled`, `guestVipArrival`, `guestComplaintRiskArrival`, `ariaComplaintRisk`.
2. Update `notification_ticket_dto.dart` (or create a sibling `notification_event_dto.dart`) to parse the broader event family. Confirm endpoint should become `GET /mobile/notifications` (general) — coordinate with backend.
3. Replace the hardcoded `route_hint == 'ticket_detail'` check with a **route-hint dispatcher**:
   ```dart
   switch (item.routeHint) {
     case 'ticket_detail':         → TicketDetailScreen
     case 'conversation_detail':   → ConversationDetailScreen
     case 'universal_request_detail': → UniversalRequestSheet
     case 'paid_service_order':    → OrderDetailScreen
     case 'guest_profile':         → GuestProfileScreen
     default: open dashboard
   }
   ```
4. Add per-kind icon + accent color in `notification_card.dart` (use `groupHexColor` + a kind→icon map).
5. Render the `priority` field: subtle for informational, accent border for actionRequired, red strip + leading icon for urgent.

**Verification:** Seed backend with one of each event type, confirm each renders correctly and deep-links to the right screen.

### Phase 3 — Realtime Robustness (1–2 days)
**Goal:** No missed events after reconnect or app resume — per the user's standing realtime rule.
1. Add `notification_updated` handler in `xano_notification_channel.dart` → patch the item in-place if present, refresh otherwise.
2. On socket `connected` event after a disconnect, trigger `notificationInboxController.refresh()` (reconcile-on-reconnect).
3. Add a `WidgetsBindingObserver` at app root that calls `refreshUnreadCount()` on `AppLifecycleState.resumed`.
4. Replace fire-and-forget `mark-read` with a retry-once-then-revert pattern, surfacing a small toast if the server rejects.

### Phase 4 — UX & Awareness (2–3 days)
1. Add a **bell badge** on the Dashboard / Tickets app-bar bell that mirrors `totalUnreadCount` (use the existing controller — no extra fetch).
2. Add a **Mentions** and **Urgent** filter (server-side filter param, or client-side if dataset is small).
3. iOS / Android **permission UX**: on first denial, show a contextual rationale; on subsequent app open with permissions still denied, show a one-time banner with a deep link to system settings (`app_settings` package).
4. Optional: small "X new" pill above the list when realtime delivers new items while the sheet is open (avoid auto-scroll).

### Phase 5 — Backend Coordination & Hygiene (parallel work)
1. Define and implement `POST /notifications/read-all` — replace the client loop.
2. Define and implement `notification_updated` server emit.
3. Define routing matrix server-side: department × event type → who gets the push. Confirm with backend that this is enforced before delivery (the MVP's "department routing logic" section).
4. Add backend rate-limiting / coalescing for high-frequency event types (e.g. don't emit a notification for every minor ticket state change — only the operationally meaningful ones per MVP §14).

### Phase 6 — Measurement (1 day)
Operations is the product, not notifications. Add lightweight analytics so we can prove the system reduces latency:
- `notification_received` (with kind, priority, timestamp)
- `notification_tapped` (with time-to-tap delta)
- `notification_dismissed_unread` (after 72 h sweep)
- Surface a weekly report: per-department average time-to-action.

---

## 6. Recommended Sequencing

| Sprint | Focus | Outcome |
|---|---|---|
| Sprint 1 | Phase 1 + Phase 3 | Push actually delivers; realtime survives reconnect / resume |
| Sprint 2 | Phase 2 | Inbox supports all MVP event sources |
| Sprint 3 | Phase 4 + Phase 5 | UX polish, badges, server read-all, route dispatcher |
| Sprint 4 | Phase 6 | Telemetry confirms operational impact |

---

## 7. Files Worth Reviewing Before Starting

- [notification_remote_datasource.dart:16](lib/features/notifications/data/datasources/notification_remote_datasource.dart:16) — the FCM-registration stub.
- [notification_inbox_item.dart:18](lib/features/notifications/domain/entities/notification_inbox_item.dart:18) — type-key mapping; needs extension.
- [notification_inbox_item.dart:119](lib/features/notifications/domain/entities/notification_inbox_item.dart:119) — the hardcoded `ticket_detail` check.
- [notification_inbox_controller.dart:173](lib/features/notifications/presentation/providers/notification_inbox_controller.dart:173) — fire-and-forget mark-read.
- [notification_inbox_controller.dart:197](lib/features/notifications/presentation/providers/notification_inbox_controller.dart:197) — N+1 mark-all-read loop.
- [xano_notification_channel.dart:52](lib/core/services/realtime/xano_notification_channel.dart:52) — realtime event router; add `notification_updated` here.
- [notifications_sheet.dart:374](lib/features/notifications/presentation/widgets/notifications_sheet.dart:374) — deep-link dispatch site.

---

*End of inspection. No source files were modified.*
