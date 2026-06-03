# Nexierge UAT Test Plan

Below is a comprehensive module-wise test case matrix for the entire app, with scenarios, steps, expected outcomes, and performance/quality notes. Use this as the acceptance test checklist for each feature area.

---

## 1. Authentication (Auth)

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| AUTH-01 | Email/password login success | Open app → enter valid email → enter valid password → submit | Login succeeds, app navigates to dashboard | Test on clean install and after logout |
| AUTH-02 | Employee code login success | Switch login mode → enter valid employee code → enter valid login code → submit | Login succeeds, app navigates to dashboard | Validate toggle retains form state |
| AUTH-03 | Invalid credentials | Submit wrong email/password or wrong employee code/code | Inline error shown; login blocked | Should not navigate away |
| AUTH-04 | Empty required fields | Leave required fields blank → submit | Validation message appears for each missing field | Should not trigger network call |
| AUTH-05 | Network failure during login | Disable network → submit valid credentials | Friendly error shown, no crash | Retry should be available |
| AUTH-06 | Session persistence after restart | Login successfully → close app → reopen | User remains logged in and is routed to HomeShell | Profile and dashboard should load without login |
| AUTH-07 | Logout flow | From profile, tap logout → confirm | App returns to login screen and session cleared | Back button should not return to secured screens |
| AUTH-08 | Device token registration | Login success → check backend / token state | App registers FCM/device token successfully | Token should be saved/persisted and not block login |

---

## 2. Dashboard

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| DASH-01 | Dashboard bootstrap loading | Login → first app launch | Shimmer/loading screen appears until data loads | Ensure no blank content during load |
| DASH-02 | KPI counts display | Dashboard loads | Four KPI cards show correct values from backend | Validate numbers match API response |
| DASH-03 | Needs Attention list | Dashboard loads | High-priority tickets appear in needs attention section | Tap item navigates to correct ticket |
| DASH-04 | Real-time KPI update | Generate ticket status change in backend / simulate socket update | KPI card updates without manual refresh | Check that counts change live |
| DASH-05 | Empty dashboard state | Backend returns zero counts / empty list | UI shows zero/empty state gracefully | No crashes, placeholder text if list empty |
| DASH-06 | Navigation from KPI cards | Tap a KPI card | App navigates to the relevant ticket list/tab | Back navigation returns to dashboard |
| DASH-07 | Performance on load | Launch dashboard on realistic data | Screen renders within acceptable time (<1s ideally) | Smooth scroll and animation without jank |

---

## 3. Tickets

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| TICK-01 | Ticket list load | Navigate to tickets tab | Ticket list loads with all applicable tickets | No blank screen, refresh icon if available |
| TICK-02 | Filter by status / tab | Switch between tabs (My tickets, department, all) | Correct tickets appear per selected scope | Check selected tab highlight |
| TICK-03 | Search by guest/room | Use search input with guest name or room number | Filtered ticket results show matching entries | Search debounce should be smooth |
| TICK-04 | Ticket detail view | Tap a ticket | Detail screen shows metadata, timeline, status, guest info | All key fields displayed and accurate |
| TICK-05 | Accept incoming ticket | Open incoming ticket → accept with ETA | Ticket status updates to accepted/in-progress | UI reflects new status and timeline entry |
| TICK-06 | Mark ticket done | In ticket detail, mark as done | Ticket becomes completed and list/status updates | Verify backend update if possible |
| TICK-07 | Add note to ticket | Add note/comment in ticket detail | Note appears in activity timeline | No duplicate entries |
| TICK-08 | Reassign ticket | Change department on ticket | Department updates and assignee changed | If UI has reassigned message, validate |
| TICK-09 | Create universal ticket | Open create screen → choose universal item → assign dept → submit | Ticket created successfully and appears in list | Validate required field enforcement |
| TICK-10 | Create catalog ticket | Open catalog create → choose service items → confirm pricing → submit | Ticket created and visible in list | Pricing and selected options should match |
| TICK-11 | Create manual ticket | Open manual create → fill guest/room/notes → submit | Ticket created successfully | Validate invalid field prevention |
| TICK-12 | Create ticket with missing required data | Leave required data blank → submit | Validation errors shown, no create call | Confirm specific missing-field messages |
| TICK-13 | Ticket API failure handling | Simulate API error during create or update | Error message appears, UI remains stable | Retry option should be available |
| TICK-14 | Real-time ticket update | Simulate external ticket change via socket | Ticket list refreshes / update arrives | No duplicate entries or stale data |
| TICK-15 | Long ticket list performance | Scroll through long list of tickets | Smooth scrolling with minimal frame drops | Ensure lazy loading or virtualization works |

---

## 4. Notifications

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| NOTIF-01 | Notification inbox open | Tap notification bell | Notifications sheet opens with unread count | Ensure sheet is scrollable |
| NOTIF-02 | Receive foreground push | Send FCM while app open | Local/foreground notification appears and inbox updates | No app crash |
| NOTIF-03 | Receive background push | Send FCM while app backgrounded | Notification appears in system tray | Tap should open app and deep link correctly |
| NOTIF-04 | Mark notification read | In inbox, mark an item as read | Item updates visually and unread badge decreases | No duplicate count changes |
| NOTIF-05 | Clear all notifications | Use clear-all action | Inbox empties or shows empty state | Confirm backend/ UI sync |
| NOTIF-06 | Tap notification deep link | Tap notification entry | App navigates to related ticket or page | Correct screen and context loaded |
| NOTIF-07 | Offline inbox view | Open notifications with no network | Cached notifications display if available | Graceful error if no data |
| NOTIF-08 | Unread badge update | Change notification read state | Bell badge updates correctly | Real-time update if push arrives |

---

## 5. Profile

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| PROF-01 | View profile details | Open profile tab | Full account and hotel details display | Verify fields: name, email, hotel, subscription |
| PROF-02 | Edit and save name | Tap edit name → change → save | Updated name persists and displays | Confirm API update or local state |
| PROF-03 | Upload avatar from gallery | Tap avatar → choose gallery → upload | New avatar displays after upload | Show upload progress |
| PROF-04 | Upload avatar from camera | Tap avatar → choose camera → upload | New avatar displays after upload | Permission requests should appear first |
| PROF-05 | Change theme mode | Toggle theme | App switches between light/dark instantly | Persisted on restart as `app.themeMode` |
| PROF-06 | Change app language | Select a different locale | UI text updates immediately | Persisted on restart as `app.locale` |
| PROF-07 | Logout | Tap logout and confirm | Session cleared and login screen shown | Subsequent back should not re-enter app |
| PROF-08 | Invalid profile update data | Enter invalid name/email if editable | Validation error shown, request blocked | No partial update |
| PROF-09 | Profile load failure | Simulate profile API failure | Error shown, app remains stable | Retry path should exist |

---

## 6. Activity Feed

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| ACT-01 | Load activity timeline | Open activity tab | Events load and group by day | Timeline rendering must be correct |
| ACT-02 | Filter by event type | Select a type filter | Only matching events remain | Filter state persists while visible |
| ACT-03 | Filter by department | Apply department filter | Only relevant events display | Use combination filters if supported |
| ACT-04 | Navigate from event | Tap event row | Opens corresponding ticket detail | If ticket unavailable, show message |
| ACT-05 | Real-time event update | Trigger new ticket event | New activity appears live | Avoid duplicates |
| ACT-06 | Empty activity state | No activity events | Empty state message shown | UI should not appear broken |
| ACT-07 | Performance on timeline scroll | Scroll event list quickly | Smooth scrolling with no freezing | Large event volumes should remain responsive |

---

## 7. Rooms

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| ROOM-01 | Room selection in ticket creation | Open ticket create screen → choose room | Room list populates and selection works | Room labels should be clear |
| ROOM-02 | Room context on tickets | Open ticket detail/list | Room number/type appears correctly | Accurate room mapping |
| ROOM-03 | No room available state | When room list is empty | UI handles missing rooms gracefully | Show placeholder or disable create |

---

## 8. FCM / Push Notifications

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| FCM-01 | Initial token registration | Launch app first time | Device token registered successfully | No blocking login or crash |
| FCM-02 | Token refresh handling | Force FCM token refresh | New token sent to backend | App continues to receive notifications |
| FCM-03 | Permissions on iOS/Android | Launch and grant/reject push perms | Permission flow works | App handles denied permission gracefully |
| FCM-04 | Notification payload handling | Send message with data payload | App routes correctly on tap | Both foreground and background should work |
| FCM-05 | App in terminated state | App not running → push arrives → tap | App launches and navigates properly | Deep link payload should still work |

---

## 9. Languages

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| LANG-01 | Change language in profile | Open language picker → choose locale | UI text updates in selected locale | Menu labels and buttons should translate |
| LANG-02 | Locale persistence after restart | Change language → close app → reopen | Selected locale remains active | `app.locale` stored properly |
| LANG-03 | Fallback to system locale | No locale saved | App uses device/system locale | Check when app first installs |
| LANG-04 | Partial translation coverage | Navigate through screens | No missing untranslated strings | Ensure `app_localizations` contains keys |

---

## 10. Modules (Placeholder tab)

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| MOD-01 | Open Modules tab | Tap the placeholder tab | Coming soon screen appears | No crash |
| MOD-02 | Placeholder UI behavior | Rotate device or switch tabs | Placeholder remains correct | No navigation issues |

---

## 11. Version Control

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| VER-01 | Optional update prompt | Backend returns optional update | Update sheet appears and local notification sends | User can continue using app |
| VER-02 | Forced update prompt | Backend returns forced update | App blocks normal usage until updated | Cannot dismiss required update |
| VER-03 | Up-to-date version | Backend returns no update | App continues normally | No prompt should appear |
| VER-04 | Version check on app launch | Cold start app | Version check runs once per session | Dialog should not repeat repeatedly |

---

## 12. Shell / Navigation

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| SHELL-01 | Bottom nav switching | Tap each bottom tab | Correct tab appears instantly | No state loss in other tabs |
| SHELL-02 | Deep link routing | Open deep link to ticket/profile | App navigates to correct screen | Works from background/terminated state |
| SHELL-03 | Back navigation across tabs | Navigate between tabs and screens | Back returns to previous screen/tab correctly | No broken route stack |
| SHELL-04 | HomeShell stability | Keep app open in background | On resume, shell restores correctly | No reload loops |

---

## 13. Cross-Cutting / Performance & Quality

| ID | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|
| PERF-01 | Cold app launch | Start app from terminated state | App loads into login/dashboard within acceptable time | Should not stall on startup |
| PERF-02 | Screen transition smoothness | Navigate through major screens | Animations and transitions feel smooth | No dropped frames on device |
| PERF-03 | Network loss resilience | Turn off network during use | App shows errors gracefully and recovers when reconnected | No crashes |
| PERF-04 | API error handling | Simulate server 500 on key calls | Friendly error appears, no app crash | Retry should work |
| PERF-05 | Offline fallback / cache | Launch app with cached data and no network | Cached dashboard/tickets show if supported | Must indicate stale data |
| PERF-06 | Memory/stability | Leave app open for extended time | No crashes or memory spikes | Especially with socket/realtime service |
| PERF-07 | Security / session expiry | Expire auth token server-side | App logs out or prompts re-login cleanly | No unauthorized access |
| PERF-08 | Localization completeness | Browse all screens in each locale | No missing strings, no layout overflow due to translations | Spanish and English at minimum |

---

## How to Use This Test Plan

1. **Start with Authentication tests** so the app can be exercised end-to-end.
2. **Run dashboard and ticket scenarios next**, since these are core operator flows.
3. **Use real backend or QA sandbox** to validate API-backed scenarios.
4. **Validate push, notifications, and version control** with device-level tests on physical devices.
5. **Use the notes column** for performance and stability observations.
6. **Mark each case as Pass/Fail** and capture screenshots for failures.

---

## Suggested Acceptance Test Coverage

### Must test before UAT
- **Authentication:** AUTH-01, AUTH-03, AUTH-06, AUTH-07
- **Dashboard:** DASH-01, DASH-02, DASH-04
- **Tickets:** TICK-01 through TICK-10
- **Notifications:** NOTIF-01 through NOTIF-06
- **Profile:** PROF-01 through PROF-06
- **Activity:** ACT-01 through ACT-04
- **FCM:** FCM-01 through FCM-04
- **Languages:** LANG-01 through LANG-03
- **Version:** VER-01 through VER-03

### Nice to verify
- **Rooms:** ROOM-01, ROOM-03
- **Modules:** MOD-01
- **Performance:** PERF-01 through PERF-08

---

## Test Execution Checklist Template

Use this to track execution:

```
Module: ________________    Date: ________________
Tester: ________________    Build: ________________

[ ] Test case passed
[ ] Test case failed (attach screenshot)
[ ] Test case blocked/deferred
[ ] Not applicable
```

---

## Sign-Off

| Role | Name | Date | Signature |
|---|---|---|---|
| QA Lead | | | |
| Product Owner | | | |
| Development Lead | | | |
