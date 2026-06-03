# Nexierge Features Overview - Complete Module Structure

**Last Updated:** June 3, 2026  
**Purpose:** Comprehensive feature inventory for test case creation and architecture understanding

---

## 📋 Table of Contents
1. [Authentication (Auth)](#authentication-auth)
2. [Dashboard](#dashboard)
3. [Tickets](#tickets)
4. [Notifications](#notifications)
5. [Profile](#profile)
6. [Activity Feed](#activity-feed)
7. [Rooms](#rooms)
8. [FCM (Firebase Cloud Messaging)](#fcm-firebase-cloud-messaging)
9. [Languages](#languages)
10. [Modules](#modules)
11. [Version Control](#version-control)
12. [Shell](#shell)

---

## Authentication (Auth)

### Main Screens/Pages
- **login_screen.dart** - Email/employee code based login with method toggle
- **register_screen.dart** - User registration (coming soon)
- **login_loading_screen.dart** - Loading state while authenticating

### Key Functionality
- Dual login modes: email + password OR employee code + login code
- Session persistence via `AuthSessionControllerProvider`
- Device token registration for FCM
- Input validation and error handling (transient vs. account state errors)
- Form state preservation across mode toggles (spec §4.1, §15.1)

### Main Use Cases & User Flows
1. **Email/Password Login**: Enter email → enter password → validate locally → submit → receive auth token
2. **Employee Code Login**: Enter employee code → enter login code → validate locally → submit → receive auth token
3. **Login Error Handling**: Surface transient errors via toast, account state errors via dialog
4. **Post-Login Navigation**: Reactive routing to `HomeShell` on successful auth session

### Data Models
- **AuthUser**: Minimal user identity (id, role, hotelId) from login response
- **LoginCredentials**: Email/password OR employee code/login code pair
- **AuthSession**: Full session with auth token, expiry, and user metadata
- **Department**: Associated user departments

### API Interactions
- **POST /auth/login**: Submit credentials → receive AuthSession
- **POST /auth/register**: User registration endpoint (not yet implemented)
- Exceptions:
  - `AuthException` - Credential/state failures
  - `AppException` - Transport-level failures

---

## Dashboard

### Main Screens/Pages
- **dashboard_screen.dart** - Main operator dashboard with KPI grid and needs attention
- **dashboard_shimmer_screen.dart** - Skeleton loader during bootstrap

### Key Functionality
- **KPI Strip Display**: Real-time stat cards (Needs Acknowledgment, In Progress, Overdue, Not Started)
- **Needs Attention List**: Highest-priority tickets requiring immediate action
- **Adaptive Header**: Animated collapsing/pinning header with stats grid
- **Tab Switching**: Quick navigation to Tickets and other main tabs
- **Notification Bell**: Access to notification inbox
- **Theme & Avatar Management**: Theme toggle and user profile access

### Main Use Cases & User Flows
1. **Dashboard Bootstrap**: Fetch counts and needs attention items on app start
2. **Real-time KPI Updates**: Stream live count updates as tickets change
3. **Operator Workflow Start**: Review KPIs → prioritize from needs attention → navigate to tickets
4. **Ticket Quick Access**: Tap from needs attention card → navigate to ticket detail

### Data Models
- **DashboardCounts**: Four metrics - incomingCount, inProgressCount, overdueCount, doneCount
- **NeedsAttentionItem**: Ticket summary with department, room, guest, status, due time
- **DepartmentInfo**: Department metadata (name, mobileIcon, iconUrl)
- **DashboardBootstrapState**: Combined counts + needs attention list for startup

### API Interactions
- **GET /dashboard/numbers**: Fetch KPI counts
- **GET /dashboard/needs_attention**: Fetch high-priority tickets
- **WebSocket Stream**: Real-time count updates as tickets change status
- Caching: Response cached for offline use

---

## Tickets

### Main Screens/Pages
- **tickets_screen.dart** - Legacy v1 ticket list view (5-tab model migration in progress)
- **ticket_detail_screen.dart** - Full ticket detail with timeline, actions, and metadata
- **create_screen.dart** - Universal request creation flow
- **manual_create_screen.dart** - Manual ticket creation
- **catalog_create_screen.dart** - Service catalog-based ticket creation

### Key Functionality
- **Ticket Lifecycle Management**: Create, accept, mark done, cancel, reassign, add notes
- **Dual Ticket Sources**:
  - Universal requests (preset items with ETA/SLA)
  - Service catalog orders (priced items with options)
- **Department Routing**: Assign tickets to departments, reassign if needed
- **Guest Context**: Track guest name, room number, check-out status
- **SLA Tracking**: Monitor ETA windows, identify overdue tickets
- **Activity Timeline**: View all events (created, accepted, done, reassigned, notes)
- **Search & Filter**: By department, status, room, guest
- **Scope Tabs**: Personal assignments, department, all hotel

### Main Use Cases & User Flows
1. **Create Universal Ticket**: Select item → quantity → notes → assign dept → submit
2. **Create Catalog Ticket**: Browse service catalog → select items → customize options → select items → confirm pricing → submit
3. **Create Manual Ticket**: Manual entry → department → guest details → notes → submit
4. **Accept Ticket**: View incoming ticket → estimate ETA → accept with eta window
5. **Work on Ticket**: Add notes → request items → monitor progress
6. **Complete Ticket**: Mark done → record resolution → optional incident notes
7. **Reassign Ticket**: Change department → notify new assignee
8. **View Detail**: See full history, activity, current status, SLA position

### Data Models
- **Ticket**: Core ticket model with status, kind, department, room, guest, items, timeline
- **TicketStatus**: Enum - incoming, accepted, inProgress, onHold, done, canceled, backlog
- **TicketKind**: Enum - universal, catalog, manual
- **TicketPriority**: Enum - p1, p2, p3
- **TicketSource**: Enum - whatsApp, guestApp, frontDesk, phone, walkIn, system
- **TicketDetail**: Extended detail from `/tickets/details` endpoint
- **RequestItem**: Line item with quantity, price, options, emoji
- **Room**: Room context (id, number, floor, type)
- **Guest**: Guest context (id, displayName, statusLine)
- **UniversalTicketItem**: Preset item with ETA/SLA
- **CatalogTicketItem**: Priced item with quantity and line total
- **ServiceCatalog**: Catalog metadata (name, logo, item count)
- **NewTicketDraft**: Input for creating tickets

### API Interactions
- **GET /tickets/all** or **GET /my-tickets**: Fetch user's tickets (with watch stream)
- **GET /tickets/details/{id}**: Fetch full ticket detail + activity timeline
- **GET /service-catalogs**: List available service catalogs
- **POST /tickets/create**: Submit new ticket (universal/catalog/manual)
- **POST /tickets/{id}/accept**: Accept with ETA estimate
- **POST /tickets/{id}/done**: Mark complete
- **POST /tickets/{id}/cancel**: Cancel ticket
- **POST /tickets/{id}/reassign**: Change department
- **POST /tickets/{id}/notes**: Add note to ticket
- **WebSocket Stream**: Real-time ticket list updates

---

## Notifications

### Main Screens/Pages
- **No dedicated screen** - Accessed via notification bell icon on header
- **NotificationsSheet**: Modal sheet showing inbox and notification list

### Key Functionality
- **Notification Inbox**: Display real-time notifications as they arrive
- **Notification Types**: Ticket updates, assignments, mentions, system alerts
- **Mark as Read**: Individual or bulk read marking
- **Dismiss/Archive**: Remove notifications from inbox
- **Deep Linking**: Tap notification → navigate to related ticket/resource
- **Local & Push Notifications**: Both supported via FCM + local services
- **Badge Management**: Unread count badge on bell icon

### Main Use Cases & User Flows
1. **Receive Notification**: FCM message arrives → local notification shown → data stored
2. **View Inbox**: Tap bell icon → slide up modal → see notification list
3. **Interact with Notification**: Tap notification → navigate to related resource
4. **Manage Notifications**: Mark read, dismiss, batch clear

### Data Models
- **NotificationEntity**: id, title, body, data (JSON), receivedAt timestamp
- **NotificationInboxItem**: Extended inbox model with actions and metadata
- **NotificationType**: Enum for ticket/system/assignment/mention types

### API Interactions
- **GET /notifications/inbox**: Fetch user notifications (paginated)
- **POST /notifications/{id}/read**: Mark as read
- **POST /notifications/clear**: Bulk clear
- **WebSocket Stream**: Real-time notification delivery
- **FCM Integration**: Firebase Cloud Messaging for push notifications

---

## Profile

### Main Screens/Pages
- **profile_screen.dart** - User profile with account, preferences, and hotel info

### Key Functionality
- **Account Management**: View/edit full name, email, employee code, avatar
- **Avatar Upload**: Camera/gallery pick → compress → upload → cache
- **Language Selection**: Choose locale (persisted to shared_preferences as `app.locale`)
- **Theme Preference**: Light/dark mode toggle (persisted as `app.themeMode`)
- **User Settings**: Display phone, associated departments, status
- **Hotel Information**: Hotel name, business email, phone, website, address, timezone
- **Subscription Details**: Plan type, active status
- **Logout**: Clear session and return to login

### Main Use Cases & User Flows
1. **View Profile**: Tap profile tab → see all user info + hotel context
2. **Edit Name**: Tap edit → update name → save (with optimistic UI)
3. **Change Avatar**: Tap avatar → pick from camera/gallery → upload → show loading
4. **Change Language**: Open language picker → select locale → apply + persist
5. **Change Theme**: Toggle light/dark → apply + persist
6. **View Hotel Info**: Scroll to hotel section → see business details
7. **Logout**: Tap logout → clear session → return to login screen

### Data Models
- **UserProfile**: Comprehensive profile entity including:
  - Account: id, fullName, email, employeeCode, role
  - Settings: lang (BCP-47), theme, status
  - Avatar: avatarUrl (nullable)
  - Hotel: hotelName, hotelBusinessEmail, hotelBusinessPhone, hotelWebsite, hotelAddress, hotelTimezone
  - Subscription: subscriptionPlan, subscriptionActive

### API Interactions
- **GET /user/profile**: Fetch user profile + hotel + subscription
- **PATCH /user/profile**: Update name, email, phone
- **POST /user/profile/avatar**: Upload avatar (multipart form)
- **PATCH /user/settings**: Update lang/theme preferences
- **POST /auth/logout**: Clear session and revoke token

---

## Activity Feed

### Main Screens/Pages
- **activity_screen.dart** - Full activity history with type filtering and day grouping

### Key Functionality
- **Activity Timeline**: Chronological feed of all ticket lifecycle events
- **Event Types**: Created, accepted, done, overdue, cancelled, note added, reassigned
- **Type Filtering**: Filter by event type (created, done, reassigned, etc.)
- **Department Filtering**: Filter by department
- **Day Grouping**: Events grouped by date with day section headers
- **Ticket Navigation**: Tap event → navigate to related ticket detail
- **Locale-Independent Labels**: Department/status names resolved at render time

### Main Use Cases & User Flows
1. **Review Day's Activity**: View activity screen → see grouped events by day
2. **Filter by Type**: Tap type chip → show only created/done/reassigned events
3. **Filter by Department**: Tap department filter → show activity for that dept
4. **Navigate from Activity**: Tap event row → jump to ticket detail
5. **Audit Trail**: See who did what and when (actor name + timestamp)

### Data Models
- **ActivityEvent**: Core activity model including:
  - Event type (created, accepted, done, overdue, cancelled, note, reassigned)
  - Ticket context (id, code, title, roomNumber, department)
  - Actor info (name, optional)
  - Timing (eta for accepted events, timestamp)
  - Optional metadata (note body, target department for reassigns)
- **ActivityType**: Enum - created, accepted, done, overdue, cancelled, note, reassigned

### API Interactions
- **GET /activity** or **GET /activity/feed**: Fetch activity events (with watch stream)
- **WebSocket Stream**: Real-time activity updates as events occur
- **Derived from**: Activity synthesized from ticket lifecycle changes in repositories

---

## Rooms

### Main Screens/Pages
- **No dedicated UI screens**
- Used as data layer for room context in tickets

### Key Functionality
- **Room Catalog**: Central repository of all rooms in the hotel
- **Room Metadata**: Room number, floor, type (Deluxe, Suite, etc.)
- **Room Lookup**: Used when creating tickets or viewing guest context

### Main Use Cases & User Flows
1. **Room Selection**: When creating ticket → select room from dropdown
2. **Room Context Display**: Show room info on ticket card/detail

### Data Models
- **Room**: Core room model
  - id (unique identifier)
  - number (display number)
  - floor (floor index)
  - type (nullable - room category)

### API Interactions
- **GET /rooms**: Fetch all available rooms (cached on startup)
- **GET /rooms/{id}**: Fetch single room details
- Rooms typically fetched as part of `/tickets/all` or `/my-tickets` response

---

## FCM (Firebase Cloud Messaging)

### Main Screens/Pages
- **No UI screens** - Background service

### Key Functionality
- **Device Token Management**: Register/update device token with backend
- **Message Reception**: Receive push notifications via Firebase Cloud Messaging
- **Local Notification Display**: Convert FCM messages to local notifications
- **Foreground Handling**: Handle messages while app is in foreground
- **Background Handling**: Handle messages while app is backgrounded or terminated
- **Deep Linking**: Extract data payload for in-app navigation

### Main Use Cases & User Flows
1. **App Startup**: Register device token with backend for first time
2. **Token Refresh**: When FCM token refreshes, send new token to backend
3. **Receive Message**: FCM message arrives → extract data → show local notification
4. **User Taps Notification**: Notification tapped → navigate to related resource

### Data Models
- **Device Token**: String identifier from FCM
- **Notification Message**: title, body, data payload (JSON)

### API Interactions
- **POST /device/register-token**: Submit device token to backend
- **Firebase Cloud Messaging**: Incoming push notifications

---

## Languages

### Main Screens/Pages
- **No dedicated screens** - Language selection via profile or in-app picker

### Key Functionality
- **Locale Persistence**: Store user's language choice in shared_preferences (`app.locale`)
- **Supported Languages**: en (English), es (Spanish), [others per l10n.yaml]
- **Boot-time Resolution**: On cold start, load locale from persistence or use hotel default
- **In-app Switching**: Language picker sheet allows mid-session language change

### Main Use Cases & User Flows
1. **Set Preferred Language**: Profile → language picker → select → apply + persist
2. **Cold Start**: App starts → load locale from shared_preferences
3. **First Login**: If no local preference, use user's profile.lang from user_settings API response

### Data Models
- **Locale**: BCP-47 language code (e.g., "en", "es")

### API Interactions
- **Persistence**: Stored locally via shared_preferences (key: `app.locale`)
- **User Settings**: User profile includes lang field from user_settings API

---

## Modules

### Main Screens/Pages
- **modules_screen.dart** - Placeholder "Coming Soon" screen

### Key Functionality
- **Tab Placeholder**: Reserved bottom-nav slot for future features
- **Coming Soon UI**: Styled placeholder indicating feature under development

### Main Use Cases & User Flows
1. **Navigate to Modules**: Tap modules tab → see "Coming soon" placeholder

### Data Models
- None yet (feature in design phase)

### API Interactions
- None yet (feature in design phase)

---

## Version Control

### Main Screens/Pages
- **No UI screens** - Background service

### Key Functionality
- **Version Tracking**: Monitor app version and API compatibility
- **Forced Upgrades**: Prevent obsolete app versions from connecting
- **Compatibility Checks**: Validate client/server API versions at startup

### Main Use Cases & User Flows
1. **App Startup**: Check version compatibility with backend
2. **Version Mismatch**: If incompatible → show upgrade prompt or prevent login

### Data Models
- **Version**: Semantic version (major.minor.patch)

### API Interactions
- **GET /version** or **GET /config/version**: Fetch required/recommended versions

---

## Shell

### Main Screens/Pages
- **HomeShell** - Main app navigation container with bottom nav
- **Bottom Navigation**: Tabs for Dashboard, Tickets, Activity, Profile, Modules

### Key Functionality
- **Tab Navigation**: Bottom nav controller manages active tab state
- **Deep Linking**: Handle deep links to specific tabs/screens
- **Route Transitions**: Animate between tabs
- **Persistent State**: Maintain scroll position in each tab

### Main Use Cases & User Flows
1. **Navigate Between Tabs**: Tap bottom nav → switch to tab view
2. **Deep Link**: Receive notification → deep link to specific ticket → navigate correctly

### Data Models
- **ShellTab**: Enum - dashboard, tickets, activity, profile, modules

---

## Test Case Categories

Based on this architecture, test cases should cover:

### 1. **Authentication Tests**
- Valid/invalid credentials
- Session persistence
- Token expiry handling
- Login error states

### 2. **Ticket Lifecycle Tests**
- Create (universal/catalog/manual)
- Accept with ETA
- Mark done
- Cancel
- Reassign
- Add notes
- Status transitions

### 3. **Real-time Tests**
- Ticket list updates via WebSocket
- Activity feed updates
- KPI count updates
- Notification delivery

### 4. **Data Model Tests**
- Entity serialization/deserialization
- DTO mapping to domain models
- Enum handling across languages

### 5. **API Integration Tests**
- Endpoint calls with valid/invalid data
- Error handling and exception mapping
- Request/response validation

### 6. **UI/Presentation Tests**
- Screen navigation and routing
- Provider state management
- Loading/error states
- Form validation

### 7. **Persistence Tests**
- Locale persistence (shared_preferences)
- Theme persistence
- Cache invalidation

### 8. **Offline Tests**
- Data availability when offline
- Sync queue when reconnected
- Error states

---

**End of Features Overview**
