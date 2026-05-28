# Notifications — Requirements & Implementation Plan

> **Core principle:** Notifications exist to accelerate operations.  
> Not engagement. Not dopamine. Every decision is evaluated against one KPI: _does this reduce operational latency?_

---

## 1. What Already Exists (Code Audit)

| File | Status | Notes |
|------|--------|-------|
| `notification_entity.dart` | ⚠️ Partial | FCM-only shape (id/title/body/data). No source, priority, readAt, deepLink |
| `notification_model.dart` | ⚠️ Partial | Maps only from FCM `RemoteMessage`. No Xano API DTO |
| `notification_remote_datasource.dart` | ⚠️ Stub | FCM token + foreground messages only. No REST calls |
| `i_notification_repository.dart` | ⚠️ Partial | FCM contract only. No fetch/markRead/pagination |
| `notification_repository_impl.dart` | ⚠️ Partial | Delegates to FCM datasource only |
| `notification_inbox_item.dart` | ✅ Good | Clean UI model. Only `newTicket` kind — needs expansion |
| `notification_inbox_controller.dart` | ❌ Mock | Hardcoded 4-item seed. No real API. No pagination. No filter |
| `notification_card.dart` | ✅ Good | Solid widget. Purple "+" icon hardcoded — needs source-aware icon |
| `notifications_sheet.dart` | ⚠️ Good shell | Missing: All/Unread tabs, pagination, pull-to-refresh |
| `xano_notification_channel.dart` | ⚠️ Partial | Joins channel correctly. Logs events. Does NOT update state |
| `xano_socket_service.dart` | ✅ Good | `joinNotificationChannel` + `messageStream` already wired |

**Summary:** The UI shell and socket plumbing are solid. The entire data layer is mock/FCM-only. The realtime channel fires and is logged but never updates any state.

---

## 2. Functional Requirements (from Canonical Doc)

### 2.1 MVP Scope — Included

- In-app notification center (bottom sheet, existing)
- Push notifications — iOS & Android (FCM plumbing exists, registration not complete)
- Read/unread sync — **user-level** (John reads ≠ Maria reads)
- Real-time updates via Xano WebSocket
- All / Unread tabs
- Pagination (limit 30, infinite scroll)
- Deep linking to correct operational surface
- Operational alerts only — no spam

### 2.2 MVP Scope — Not Included

- Notification preferences per event type
- Smart digesting / batching
- AI prioritization
- Quiet hours / escalation chains
- Custom sounds / vibration
- Email / SMS fallback
- Archive state
- Wearables

---

## 3. Notification Sources & Event Catalogue

| Source | MVP Events | Example Push |
|--------|-----------|--------------|
| **Tickets** | ticket_created, ticket_assigned, ticket_overdue, ticket_escalated, ticket_completed | "Housekeeping — Extra Towels overdue" |
| **Inbox** | new_guest_message, conversation_assigned, mention_tag | "Room 1207 replied on WhatsApp" |
| **Universal Requests** | new_request, request_overdue | "New request — Extra pillows — Room 504" |
| **Paid Services** | new_order, order_cancelled | "Room Service order #RS-4821 accepted" |
| **Guests & Rooms** | vip_arrival, complaint_risk_arrival | "VIP arrival — Room 305" |
| **ARIA** | complaint_risk_alert | "ARIA Alert — Guest in 305 has repeated complaint history" |

### Urgency Levels

| Type | Level | Visual Treatment |
|------|-------|-----------------|
| `informational` | Low | Default card |
| `action_required` | Medium | Amber left-border accent |
| `urgent` | High | Red left-border accent + bold title |

### Spam Prevention Rule

Only notify on **meaningful operational moments**:
- ✅ New request, escalation, overdue, guest reply after silence
- ❌ "typing", every minor update, internal sync, analytics

---

## 4. Notification Lifecycle

```
UNREAD → READ      (MVP)
READ   → ARCHIVED  (future)
```

State fields: `unread_at` (int ms), `read_at` (int ms, nullable).

**Read is user-level.** Underlying ticket/object state is global — but the notification read flag belongs to the individual user who received it.

---

## 5. Deep Linking

Every notification tap must navigate to the correct surface:

| Source | Deep Link Target | Required Params |
|--------|-----------------|----------------|
| Ticket any event | Ticket detail screen | `ticket_id` |
| Inbox message | Inbox conversation | `conversation_id` |
| Universal Request | Ticket detail | `ticket_id` |
| Paid Service order | Order detail | `order_id` |
| Guest VIP / complaint | Guest profile | `guest_id` |

---

## 6. Real-Time Sync

Notifications sync across mobile and web instantly via Xano WebSocket.

**Realtime channel:**
```
hub_notifications/{hotel_id}/{hub_preset_id}
```

**How `hub_preset_id` is resolved (confirmed):**
```dart
// From userProfile.accessControl.hubAccess — filter hubCode == 'tickets'
final ticketsHub = userProfile.accessControl.hubAccess
    .where((h) => h.hubCode == 'tickets' && h.hubPresetId.isNotEmpty)
    .firstOrNull;
// ticketsHub.hubPresetId → channel segment
```

**Channel join status:** ✅ Already correct. `dashboard_bootstrap_controller.dart` already calls `socketService.joinHubNotificationsChannel(hotelId, ticketsHub.hubPresetId)` immediately after `auth/me`. No fix needed here.

**What IS broken:** `xanoHubNotificationsLoggerProvider` (watched in `main.dart`) only logs incoming `hub_notifications` events — it never updates `NotificationInboxController` state. This is the gap to fix.

**Realtime event shape (notification_read):**
```json
{
  "label": "hub",
  "channel": "hub_notifications/{hotel_id}/{hub_preset_id}",
  "payload": {
    "event_action": "notification_read",
    "notification_event_id": "feadcf98-...",
    "status": "emitted_and_read",
    "read_by_hotel_user_id": "0e013e94-...",
    "updated_at": 1779896873450
  }
}
```

When `event_action == "notification_read"`:
- If `read_by_hotel_user_id == currentUserId` → call `notificationInboxController.markReadLocally(id)`
- If different user → no-op (user-level isolation)

---

## 7. APIs

### 7.1 Fetch Notifications

```
POST https://xvmf-wx0g-xvlj.b2.xano.io/api:9SaoW0J_/mobile/notifications/tickets
```

**Request:**
```json
{
  "hotel_id": "<string>",
  "hotel_user_id": "<string>",
  "limit": "30",
  "offset": "0",
  "status_filter": "all",   // "all" | "read" | "unread"
  "scope_filter": "all"     // "all" | department-id (future)
}
```

Notes:
- `limit` / `offset` are strings (not ints) — send as strings
- `status_filter` drives the All/Unread tabs
- `scope_filter` for MVP always `"all"`

### 7.2 Mark Notification as Read

```
POST https://xvmf-wx0g-xvlj.b2.xano.io/api:9SaoW0J_/notifications/mark-read
```

**Request:**
```json
{
  "hotel_id": "<string>",
  "hotel_user_id": "<string>",
  "notification_event_id": "<string>"
}
```

Call this when:
- User taps a notification card (single read)
- User taps "Mark all as read" (call for each unread — or await dedicated endpoint)

### 7.3 Realtime Channel

Already joined via `xanoNotificationChannelProvider`. Needs correction on channel ID format (see §6).

---

## 8. Gaps — What Must Be Built

| # | Gap | Priority | Notes |
|---|-----|----------|-------|
| G1 | Xano DTO for API response + `APIEndpoints` constants | 🔴 Blocker | Path prefix: `/api:9SaoW0J_` |
| G2 | `INotificationRepository` + impl: `fetchNotifications`, `markAsRead` | 🔴 Blocker | Use `dioClientProvider` |
| G3 | `NotificationInboxController` wired to real API (replace mock seed) | 🔴 Blocker | |
| G4 | All/Unread tab logic in controller + sheet | 🔴 Must | `statusFilter` param |
| G5 | Pagination (offset/limit, load-more on scroll 80%) | 🔴 Must | |
| G6 | `xanoHubNotificationsLoggerProvider` → update state on `notification_read` | 🔴 Must | Already watched in `main.dart` |
| G7 | ~~Channel ID fix~~ | ✅ Already correct | Bootstrap does it right |
| G8 | Source-aware icons per `NotificationInboxKind` | 🟡 Should | |
| G9 | Priority accent (amber/red left-border on card) | 🟡 Should | |
| G10 | Pull-to-refresh in sheet | 🟡 Should | |
| G11 | Deep link handler for all 5 target types | 🟡 Should | |
| G12 | FCM device token registration to backend | 🟡 Should | `POST /fcm_update` already in endpoints |
| G13 | `NotificationInboxKind` enum expanded (all 6 sources) | 🟡 Should | |

---

## 9. Implementation Plan

### Phase 1 — Data Layer (Xano API)

**Step 0: Add API endpoint constants**

File: `lib/core/network/api_endpoints.dart` — add under the relevant section:
```dart
static const String _notificationsPath = '/api:9SaoW0J_';
static const String mobileNotificationsTickets =
    '$baseUrl$_notificationsPath/mobile/notifications/tickets';
static const String notificationsMarkRead =
    '$baseUrl$_notificationsPath/notifications/mark-read';
```

**Step 1: Create Xano DTO**

File: `lib/features/notifications/data/dtos/notification_ticket_dto.dart`

```dart
/// Maps to the Xano API response from POST /mobile/notifications/tickets.
/// Field names will be confirmed when the API response is available.
class NotificationTicketDto {
  final String id;               // notification_event_id
  final String hotelId;
  final String hotelUserId;
  final String eventAction;      // "new_ticket", "ticket_overdue", etc.
  final String audienceScope;    // "hub"
  final String? targetTicketId;
  final String? targetOrderId;
  final String? targetGuestId;
  final String? targetConversationId;
  final String title;
  final String body;
  final String status;           // "emitted" | "emitted_and_read"
  final String? readByHotelUserId;
  final int createdAt;           // epoch ms
  final int? updatedAt;

  bool get isRead => status == 'emitted_and_read';

  factory NotificationTicketDto.fromJson(Map<String, dynamic> json) { ... }
}
```

**Step 2: Extend domain entity**

File: `lib/features/notifications/domain/entities/notification_entity.dart`  
Replace existing FCM-only entity with operational entity:

```dart
enum NotificationSource { tickets, inbox, universalRequests, paidServices, guests, aria }
enum NotificationPriority { informational, actionRequired, urgent }

class NotificationEntity {
  final String id;
  final NotificationSource source;
  final NotificationPriority priority;
  final String eventAction;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationDeepLink? deepLink;
}
```

**Step 3: Extend `INotificationRepository`**

```dart
abstract class INotificationRepository {
  // Existing FCM methods kept
  Future<String?> getFCMToken();
  Future<void> registerToken(String token);
  Stream<NotificationEntity> get onNotificationReceived;

  // New Xano REST methods
  Future<List<NotificationEntity>> fetchNotifications({
    required String hotelId,
    required String hotelUserId,
    required int limit,
    required int offset,
    required String statusFilter,   // "all" | "unread" | "read"
    required String scopeFilter,    // "all"
  });

  Future<void> markAsRead({
    required String hotelId,
    required String hotelUserId,
    required String notificationEventId,
  });
}
```

**Step 4: Implement datasource + repository**

`NotificationRemoteDataSource` gains two new methods using the existing Dio client:
- `fetchNotifications(...)` → `POST /mobile/notifications/tickets`
- `markAsRead(...)` → `POST /notifications/mark-read`

---

### Phase 2 — State Management

**Step 5: Replace mock controller with real controller**

File: `lib/features/notifications/presentation/providers/notification_inbox_controller.dart`

```dart
// State shape
class NotificationInboxState {
  final List<NotificationInboxItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String statusFilter;   // "all" | "unread"
  final String? error;

  int get unreadCount => items.where((i) => i.unread).length;
  int get totalCount => items.length;
}
```

Controller responsibilities:
1. `build()` — calls `fetchNotifications(offset: 0, statusFilter: "all")` on init
2. `switchTab(String filter)` — resets list, fetches with new `statusFilter`
3. `loadMore()` — appends next page (offset += 30), guarded by `hasMore`
4. `markRead(String id)` — calls API + updates local state optimistically
5. `markAllAsRead()` — calls API for each unread (or bulk endpoint) + updates state
6. `refresh()` — resets offset, re-fetches

**Step 6: Wire realtime events to state**

File: `lib/core/services/realtime/xano_notification_channel.dart`

Replace logger-only provider with event handler:

```dart
final xanoNotificationRealtimeProvider = Provider<void>((ref) {
  final socket = ref.watch(xanoSocketServiceProvider);
  
  final sub = socket.messageStream.listen((raw) {
    final msg = _parseMessage(raw);
    if (msg == null || !msg.channel.startsWith('hub_notifications')) return;

    final payload = msg.payload;
    final eventAction = payload['event_action'] as String?;

    if (eventAction == 'notification_read') {
      final notificationId = payload['notification_event_id'] as String;
      final readBy = payload['read_by_hotel_user_id'] as String;
      final currentUserId = ref.read(currentUserIdProvider);

      if (readBy == currentUserId) {
        ref.read(notificationInboxControllerProvider.notifier)
           .markReadLocally(notificationId);
      }
    }
    // Future: handle "notification_created" → prepend to list
  });

  ref.onDispose(sub.cancel);
});
```

**Step 7: Fix channel ID**

`joinNotificationChannel` currently passes `userId` as the last segment.  
The realtime channel is `hub_notifications/{hotel_id}/{hub_preset_id}`.

The `hub_preset_id` must come from the user profile (dashboard bootstrap).  
Identify field in `UserProfile` that holds `hub_preset_id` and pass it instead of `userId`.

---

### Phase 3 — UI Layer

**Step 8: Add All / Unread tabs to `NotificationsSheet`**

```dart
// Above the card list, add a TabBar or segmented control:
// [All]  [Unread (4)]
// Tapping switches calls controller.switchTab("all" | "unread")
```

Implementation: `DefaultTabController(length: 2)` with `TabBar` inside the sheet column, above `_Body`.

**Step 9: Pagination — infinite scroll**

In `_Body.build()`, add scroll listener on `scrollController`:
```dart
scrollController.addListener(() {
  if (scrollController.position.pixels >= 
      scrollController.position.maxScrollExtent * 0.8) {
    ref.read(notificationInboxControllerProvider.notifier).loadMore();
  }
});
```
Show `CircularProgressIndicator` at list bottom when `isLoadingMore == true`.

**Step 10: Pull-to-refresh**

Wrap `ListView` in `RefreshIndicator`:
```dart
RefreshIndicator(
  onRefresh: () => ref.read(...notifier).refresh(),
  child: ListView.separated(...),
)
```

**Step 11: Source-aware icons in `NotificationCard`**

Expand `NotificationInboxKind`:
```dart
enum NotificationInboxKind {
  newTicket,          // LucideIcons.ticket — purple
  ticketOverdue,      // LucideIcons.clock — amber
  ticketEscalated,    // LucideIcons.alertTriangle — red
  ticketCompleted,    // LucideIcons.checkCircle — green
  inboxMessage,       // LucideIcons.messageCircle — blue
  universalRequest,   // LucideIcons.clipboardList — purple
  paidServiceOrder,   // LucideIcons.shoppingCart — teal
  guestArrival,       // LucideIcons.user — gold
  ariaAlert,          // LucideIcons.brain — orange
}
```

`_LeadingIcon` uses `item.kind` to select icon + color pair.

**Step 12: Priority accent on card**

For `actionRequired` → 2px amber left border on card container.  
For `urgent` → 2px red left border + title in bold-red.  
Add `priority` field to `NotificationInboxItem`.

**Step 13: Deep link expansion**

`NotificationInboxItem` gains:
```dart
final NotificationDeepLink? deepLink;
```

```dart
class NotificationDeepLink {
  final DeepLinkTarget target;
  final Map<String, String> params;
}

enum DeepLinkTarget {
  ticketDetail,
  inboxConversation,
  orderDetail,
  guestProfile,
}
```

`_onItemTap` in `_Body` becomes:
```dart
void _onItemTap(context, ref, item) {
  ref.read(...notifier).markRead(item.id);
  final link = item.deepLink;
  if (link == null) return;
  Navigator.of(context).pop();
  switch (link.target) {
    case DeepLinkTarget.ticketDetail:
      onOpenTicket?.call(link.params['ticket_id']!);
    case DeepLinkTarget.inboxConversation:
      onOpenConversation?.call(link.params['conversation_id']!);
    // ... etc
  }
}
```

`NotificationsSheet.show()` gains optional callbacks per deep link target.

---

### Phase 4 — Push Notifications (FCM)

**Step 14: Complete device registration**

`NotificationRemoteDataSource.registerToken()` currently a TODO.  
Wire it to `POST /mobile/devices/register` once that endpoint exists.

**Step 15: Handle background tap → deep link**

When app launched from a killed state via push tap:
- `FirebaseMessaging.instance.getInitialMessage()` → extract deep link params → navigate after app boot

---

## 10. Notification Card — Final UX Spec

```
┌─────────────────────────────────────────────────┐
│ [●] [ICON]  Title (bold)               7h ago ● │
│             Subtitle · Dept · Room              │
└─────────────────────────────────────────────────┘
  ↑             ↑                         ↑      ↑
priority     source                    relative  unread
accent       icon                      time      dot
```

- `●` = priority left-border accent (invisible for `informational`)
- Unread dot = purple circle, hidden when `isRead == true`
- Tap → mark read + navigate to deep link target
- Long press (future) → contextual menu (archive, snooze)

---

## 11. NotificationsSheet — Final Tab Layout

```
┌────────────────────────────────────┐
│              ▬▬▬                   │  ← drag handle
│ Notifications        ×             │  ← header + close
│ 4 unread                           │
│ Mark all as read      32 total     │  ← actions row
│ ┌──────────┬──────────┐            │
│ │   All    │ Unread(4)│            │  ← tabs ← NEW
│ └──────────┴──────────┘            │
│ ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ │
│ [card]                             │
│ [card]                             │
│ [card] ← pull-to-refresh           │
│ ...                                │
│ ← load more on scroll 80%         │
└────────────────────────────────────┘
```

---

## 12. Suggested File Change Map

```
lib/features/notifications/
├── data/
│   ├── datasources/
│   │   └── notification_remote_datasource.dart     MODIFY — add fetchNotifications, markAsRead
│   ├── dtos/
│   │   └── notification_ticket_dto.dart            CREATE
│   └── repositories/
│       └── notification_repository_impl.dart       MODIFY — implement new interface methods
├── domain/
│   ├── entities/
│   │   ├── notification_entity.dart                MODIFY — full operational entity
│   │   └── notification_inbox_item.dart            MODIFY — add priority, deepLink, expand kind
│   └── repositories/
│       └── i_notification_repository.dart          MODIFY — add fetch/markRead methods
└── presentation/
    ├── providers/
    │   └── notification_inbox_controller.dart      MODIFY — real API, tabs, pagination
    └── widgets/
        ├── notification_card.dart                  MODIFY — source icons, priority accent
        └── notifications_sheet.dart               MODIFY — tabs, pull-to-refresh, pagination

lib/core/services/realtime/
└── xano_notification_channel.dart                 MODIFY — handle read events → update state
```

---

## 13. Open Questions Before Implementation

| # | Question | Status | Impact |
|---|----------|--------|--------|
| Q1 | `hub_preset_id` field path in UserProfile? | ✅ Resolved: `userProfile.accessControl.hubAccess.firstWhere(h.hubCode == 'tickets').hubPresetId` | Channel join (already correct) |
| Q2 | Full Xano API response shape for `POST /mobile/notifications/tickets`? | ⏳ Need response sample | DTO field names (G1) |
| Q3 | Does realtime channel emit `notification_created` for new arrivals? | ⏳ Confirm | Live prepend to list |
| Q4 | Is there a bulk mark-all-read endpoint? | ⏳ Confirm | `markAllAsRead` impl — call per item or single call |
| Q5 | ~~Per-user or per-hotel hub_preset_id?~~ | ✅ Resolved: per tickets-hub (hub_code == 'tickets') | — |

---

## 14. Final Principle

> Notifications are not the product. Operations are the product.  
> Notifications only exist to accelerate operations.

Every implementation decision maps to this. If it doesn't reduce operational latency or improve awareness — it doesn't ship in MVP.
