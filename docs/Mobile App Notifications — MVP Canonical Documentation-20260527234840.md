# Mobile App Notifications — MVP Canonical Documentation

## Uncomfortable Truth
If notifications are not deeply tied to operational actions, they become noise in less than 7 days.
Hotels already ignore emails, radios, WhatsApp groups, and PMS alerts.
If Nexierge notifications are just “message received” spam, the product loses operational trust immediately.
The notification system must exist for one reason only:
> Drive operational action fast enough to improve guest experience, SLA, and revenue.
Not “engagement.”
Not dopamine.
Not social-app behavior.
* * *
# 1\. Purpose
The Mobile Notification System allows Nexierge staff users to receive real-time operational alerts directly on mobile devices.
The system exists to support:
*   Faster ticket response
*   Operational awareness
*   Reduced missed requests
*   Real-time execution
*   Cross-department visibility
*   Urgent escalation handling
Notifications are an operational layer.
Not a communication product.
This system is tightly connected to:
*   Inbox
*   Tickets
*   Universal Requests
*   Paid Services
*   Guests & Rooms
*   Hotel Crew
*   ARIA signals
Based on the architecture already defined across Nexierge.
* * *
# 2\. Core Principle
Notifications are event-driven.
A notification is never created manually.
Every notification comes from a system event.
Examples:
*   New ticket assigned
*   Universal Request created
*   Paid Service order status updated
*   New WhatsApp message
*   Mention/tag
*   Escalation
*   Guest complaint risk
*   Ticket overdue
*   Staff reassignment
Notifications are:
*   Real-time
*   Action-oriented
*   Contextual
*   Permission-aware
* * *
# 3\. MVP Scope
MVP notifications support only:
## Included
*   Push notifications (iOS / Android)
*   In-app notification center
*   Read/unread sync
*   Real-time updates
*   Basic notification grouping
*   Deep linking
*   Operational alerts only
## Not Included Yet
*   Notification preferences per event type
*   Smart digesting
*   AI prioritization
*   Notification batching intelligence
*   Quiet hours
*   Escalation chains
*   Sound customization
*   Wearables
*   Email fallback
*   SMS fallback
* * *
# 4\. Notification Sources
## 4.1 Inbox Events
Examples:
*   New WhatsApp message
*   Guest reply
*   New OTA message
*   New Instagram DM
*   Mention in conversation
*   Conversation assigned
Connected to the omnichannel architecture.
Example push:
> “Room 1207 replied on WhatsApp”
* * *
## 4.2 Ticket Events
Examples:
*   New ticket routed to department
*   Ticket assigned
*   Ticket accepted
*   Ticket overdue
*   Ticket escalated
*   Ticket completed
Tickets are department-based, not delivery-based.
Example:
> “Housekeeping — Extra Towels request overdue”
* * *
## 4.3 Universal Requests
Examples:
*   Guest requested towels
*   Maintenance request created
*   New housekeeping request
Universal Requests are operational and real-time.
Example:
> “New request — Extra pillows — Room 504”
* * *
## 4.4 Paid Services
Examples:
*   New Room Service order
*   Spa booking confirmed
*   Order cancelled
*   Delivery delayed
Connected to Paid Service catalogs.
Example:
> “Room Service order #RS-4821 accepted”
* * *
## 4.5 Guests & Rooms
Examples:
*   VIP check-in
*   Complaint-risk guest checked in
*   Room status changed
*   Emergency room move
Connected to operational hotel structure.
* * *
## 4.6 ARIA Signals (Very Basic in MVP)
MVP only supports lightweight operational intelligence signals.
Examples:
*   High complaint risk
*   VIP detected
*   Repeated unresolved issue
ARIA learns from operational signals.
Example:
> “ARIA Alert — Guest in Room 305 has repeated complaint history”
* * *
# 5\. Notification Types
## 5.1 Informational
Low urgency.
Examples:
*   Ticket completed
*   Guest replied
*   Order delivered
* * *
## 5.2 Action Required
Requires staff action.
Examples:
*   New ticket assigned
*   Guest waiting
*   Request not accepted
* * *
## 5.3 Urgent
Operational urgency.
Examples:
*   Complaint escalation
*   VIP unresolved issue
*   Overdue maintenance
*   Emergency room change
Urgent notifications may later support:
*   Different sounds
*   Repeated alerts
*   Escalation logic
Not in MVP.
* * *
# 6\. Notification Lifecycle
## States

```cpp
UNREAD
READ
ARCHIVED (future)
```

MVP only needs:
*   unread\_at
*   read\_at
No complex states.
* * *
# 7\. Read Logic
Critical rule:
Notifications are user-level.
Not global.
If John reads a notification:
*   only John’s notification becomes read
*   not Maria’s
Because notifications represent awareness.
Not ticket state.
However:
The underlying object updates globally.
Example:
*   Ticket completed
*   → related notifications may auto-close visually
* * *
# 8\. Deep Linking
Every notification must open the correct operational surface.
Examples:

| Notification | Opens |
| ---| --- |
| WhatsApp message | Inbox conversation |
| Universal Request | Ticket detail |
| Room Service order | Order detail |
| Complaint escalation | Ticket |
| VIP check-in | Guest profile |

Notifications are navigation accelerators.
Not standalone content.
* * *
# 9\. Mobile Notification Center
The mobile app contains a notification center.
Simple MVP structure:
## Tabs
*   All
*   Unread
Optional later:
*   Mentions
*   Urgent
*   Assigned to me
* * *
# 10\. Notification Card Structure
Each notification card contains:
*   Icon
*   Event title
*   Short description
*   Relative timestamp
*   Read/unread indicator
*   Priority indicator
*   Deep link target
Example:

```python
🧻 Extra towels requested
Room 1207 · Housekeeping
2 min ago
```

* * *
# 11\. Real-Time Sync
Notifications sync across:
*   Mobile app
*   Web app
If notification read on web:
→ mobile updates instantly
If read on mobile:
→ web updates instantly
Uses same realtime architecture already planned for Inbox/Tickets.
* * *
# 12\. Push Notification Rules
Push notifications are sent only when:
*   user has permission
*   user belongs to relevant department
*   event is operationally relevant
Example:
Housekeeping staff should NOT receive:
*   Front Desk-only notifications
*   Finance notifications
*   Spa notifications
Connected to Hotel Crew permissions architecture.
* * *
# 13\. Department Routing Logic
Notifications follow the same routing philosophy as Tickets.
Department responsibility first.
Example:
Universal Request:
→ Department = Housekeeping
Notifications sent to:
*   Housekeeping managers
*   Housekeeping staff
*   Operational leads (optional)
Not entire hotel.
* * *
# 14\. Avoiding Notification Spam
Critical MVP rule:
Do NOT notify every state change.
Only meaningful operational moments.
Good:
*   New request
*   Escalation
*   Overdue
*   Guest reply after long silence
Bad:
*   “typing”
*   every minor update
*   internal sync events
*   analytics updates
Operational clarity > activity feed.
* * *
# 15\. Suggested MVP Notification Events
## Inbox
*   New guest message
*   Conversation assigned
*   Mention/tag
## Tickets
*   Ticket created
*   Ticket assigned
*   Ticket overdue
*   Ticket escalated
*   Ticket completed
## Universal Requests
*   New request
*   Request overdue
## Paid Services
*   New order
*   Order cancelled
## Guests & Rooms
*   VIP arrival
*   Complaint-risk arrival
## ARIA
*   Complaint risk alert
* * *
# 16\. API Architecture (Simple MVP)
## Device Registration

```cpp
POST /mobile/devices/register
```

Stores:
*   user\_id
*   push\_token
*   platform
*   app\_version
* * *
## Fetch Notifications

```sql
GET /notifications
```

Supports:
*   unread\_only
*   pagination
* * *
## Mark Read

```bash
POST /notifications/{id}/read
```

* * *
## Mark All Read

```perl
POST /notifications/read-all
```

* * *
## Realtime Event
Existing realtime infrastructure pushes:

```json
{
  "type": "notification.created",
  "notification": {}
}
```

* * *
# 17\. Suggested Realtime Events

```cpp
notification.created
notification.updated
notification.read
notification.deleted (future)
```

Simple.
Enough for MVP.
* * *
# 18\. Mobile UX Principle
The mobile app is not another inbox.
The mobile app exists for:
*   operational speed
*   awareness
*   action execution
Notifications must reduce operational latency.
That is the KPI.
Not clicks.
Not opens.
* * *
# 19\. What Success Looks Like
Good notification system:
*   Staff reacts faster
*   Fewer missed requests
*   Less radio/WhatsApp chaos
*   Better SLA
*   Better guest satisfaction
*   Better operational visibility
Bad notification system:
*   Noise
*   Spam
*   Ignored alerts
*   Alert fatigue
Hotels already suffer from this.
Do not recreate it digitally.
* * *
# 20\. Final Principle
Notifications are not the product.
Operations are the product.
Notifications only exist to accelerate operations.