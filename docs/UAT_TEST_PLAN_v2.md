# Nexierge — UAT Test Plan & QA Handbook (v2)

**Document owner:** QA Lead
**Last updated:** 2026-06-03
**Status:** Draft for UAT sign-off
**Supersedes:** `UAT_TEST_PLAN.md` (v1)

---

## 1. Purpose & Scope

This document is the canonical acceptance-test reference for the Nexierge mobile app (HotelOps). It defines:

- The features under test and their acceptance criteria.
- The environment, test data, and tooling required to execute UAT.
- The defect lifecycle, severity matrix, and exit criteria.
- The roles and responsibilities for sign-off.

**In scope:** Flutter mobile app (Android + iOS), backend integration, FCM push, Socket.IO realtime, version control, i18n.
**Out of scope:** Backend-only API correctness (covered by API test suite), admin web console, infra/SRE concerns.

---

## 2. Test Environment

| Item | Value |
|---|---|
| Backend environment | `uat.nexierge.io` (sandbox) |
| Socket endpoint | `wss://uat.nexierge.io/realtime` |
| FCM project | `nexierge-uat` |
| App build channel | `uat` flavor, signed UAT keystore (Android) / TestFlight (iOS) |
| Min Android | API 24 (Android 7) |
| Min iOS | iOS 14 |
| Required devices | 1× low-end Android (e.g. Pixel 4a), 1× recent Android (Pixel 8 / Samsung S23), 1× iPhone (XR or later), 1× iPad (optional) |
| Network conditions | WiFi, 4G, 3G-throttled, Offline (via Charles / Network Link Conditioner) |
| Locales to verify | `en`, `es` (+ any locale active in `app_localizations`) |

### 2.1 Test Data Setup

Before UAT begins, the QA lead must seed:

- **Users:** at least one per role (FrontDesk, Housekeeping, Maintenance, F&B, Manager/Admin).
- **Rooms:** ≥20 rooms across multiple floors; include OOO/OOS states.
- **Tickets:** seed open, in-progress, completed, and overdue tickets across departments.
- **Catalog:** at least 5 priced catalog items + 3 universal items.
- **Notifications:** trigger a backlog of ≥10 unread notifications per test user.
- **Version control:** server-flagged "optional" and "forced" update payloads ready to toggle.

Credentials are stored in 1Password vault **`Nexierge-UAT`** (request access from QA lead).

---

## 3. Roles & Responsibilities (RACI)

| Activity | QA Lead | QA Tester | Dev | PM | Stakeholder |
|---|---|---|---|---|---|
| Test plan ownership | **R/A** | C | C | I | I |
| Test execution | A | **R** | I | I | I |
| Defect triage | R | C | **A** | C | I |
| Severity assignment | **R/A** | C | C | I | I |
| Sign-off | C | I | C | **R** | **A** |

R = Responsible, A = Accountable, C = Consulted, I = Informed.

---

## 4. Entry Criteria

UAT begins only when **all** of the following are true:

1. Latest UAT build deployed to TestFlight / Firebase App Distribution.
2. Backend UAT environment healthy (smoke test green).
3. Test data seeded (§2.1).
4. Known critical (P0/P1) defects from prior cycle are closed or have approved waivers.
5. Release notes published, listing changes since last cycle.

---

## 5. Exit Criteria

UAT is **passed** when:

- 100% of P0/P1 test cases pass.
- ≥95% of P2 test cases pass; any failures have agreed mitigation.
- Zero open P0/P1 defects.
- ≤3 open P2 defects, each with an agreed workaround or scheduled fix.
- Performance benchmarks (§16) within thresholds on at least one Android + one iOS device.
- Sign-off captured from PM and Stakeholder (§22).

---

## 6. Defect Severity Matrix

| Severity | Definition | Example | Target fix |
|---|---|---|---|
| **P0 — Critical** | App unusable, data loss, security breach, crash on launch | Cannot log in; tickets lost on save | Same day |
| **P1 — High** | Major feature broken, no workaround | Push notifications not delivered; cannot create ticket | Within cycle |
| **P2 — Medium** | Feature degraded, workaround exists | Filter resets on tab switch; minor i18n gap | Next cycle |
| **P3 — Low** | Cosmetic, edge case | Misaligned icon at certain zoom | Backlog |

### 6.1 Defect Report Template

```
ID:           DEF-YYYYMMDD-###
Title:        <one-line summary>
Severity:     P0 | P1 | P2 | P3
Module:       Auth | Dashboard | Tickets | …
Build:        <version + buildNumber>
Device/OS:    <model, OS version>
Network:      WiFi | 4G | Offline
Locale:       en | es | …
Steps:        1. … 2. … 3. …
Expected:     <what should happen>
Actual:       <what happened>
Frequency:    Always | Intermittent | Once
Attachments:  <screenshot/video/log refs>
Logs:         <crashlytics ID / log excerpt>
Notes:        <regression? blocking other tests?>
```

---

## 7. Test Case Conventions

- **ID format:** `<MODULE>-<NN>` (e.g., `TICK-05`). Stable across cycles.
- **Priority column** added to every test case: **P0** (must-pass), **P1** (must-pass for release), **P2** (should-pass), **P3** (nice-to-have).
- Each case records: scenario, steps, expected outcome, priority, and notes.
- Pass/Fail captured per device + locale in the execution sheet.

---

## 8. Authentication (Auth)

| ID | Priority | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|---|
| AUTH-01 | P0 | Email/password login success | Open app → enter valid email → password → submit | Login succeeds, navigates to dashboard | Clean install + post-logout |
| AUTH-02 | P0 | Employee code login success | Toggle mode → enter employee code + login code → submit | Login succeeds | Verify toggle retains form state |
| AUTH-03 | P0 | Invalid credentials | Submit wrong creds | Inline error, login blocked | Should not navigate |
| AUTH-04 | P1 | Empty required fields | Blank fields → submit | Validation per field; no network call | |
| AUTH-05 | P1 | Network failure during login | Disable network → submit valid creds | Friendly error, no crash; retry available | |
| AUTH-06 | P0 | Session persistence | Login → kill → relaunch | User remains logged in, routes to HomeShell | |
| AUTH-07 | P0 | Logout | Profile → logout → confirm | Session cleared, login screen; back-stack not re-entered | |
| AUTH-08 | P1 | Device token registration | Login → inspect token state | FCM token registered/persisted, doesn't block login | |
| AUTH-09 | P1 | Token expiry mid-session | Force-expire token server-side, perform protected action | App refreshes silently or prompts re-login; no silent failure | New |
| AUTH-10 | P1 | Concurrent login on second device | Log in on Device B with same account | Define behaviour: allowed concurrent OR Device A invalidated. Confirm matches spec | New |
| AUTH-11 | P2 | Deep link while logged out | Open ticket deep link with no session | Routes to login; after login returns to original target | New |
| AUTH-12 | P2 | Biometric/quick re-auth (if enabled) | Enable biometric → relaunch | Prompt appears; fallback to password works | New — skip if feature not shipped |
| AUTH-13 | P2 | Brute force / rate limit feedback | Submit wrong creds repeatedly | Server-side throttle reflected in UI (e.g., "try again in N s") | New |
| AUTH-14 | P2 | Login with leading/trailing whitespace | Paste email with spaces | Trimmed and accepted, or clear validation message | New |

---

## 9. Dashboard

| ID | Priority | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|---|
| DASH-01 | P0 | Bootstrap loading | Login → first launch | Shimmer until data loads; no blank content | |
| DASH-02 | P0 | KPI counts accuracy | Dashboard loads | Four KPI values match API response | Cross-check API |
| DASH-03 | P1 | Needs Attention list | Dashboard loads | High-priority tickets shown; tap → correct detail | |
| DASH-04 | P0 | Real-time KPI update | Trigger ticket change via socket | Counts update without manual refresh | |
| DASH-05 | P1 | Empty state | Zero counts | Graceful empty UI, no crash | |
| DASH-06 | P1 | KPI navigation | Tap KPI card | Routes to filtered ticket list; back returns to dashboard | |
| DASH-07 | P1 | Pull-to-refresh | Swipe down | Triggers refetch; spinner shown; data updates | New |
| DASH-08 | P2 | Stale data indicator after reconnect | Lose connection → regain | Indicator shows refresh; reconciliation runs | New |
| DASH-09 | P1 | Performance on cold load | Launch with realistic data | First paint < 1s on mid-tier device | See §16 |
| DASH-10 | P2 | RBAC visibility | Login as restricted role | Only role-permitted KPIs visible | New |

---

## 10. Tickets

| ID | Priority | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|---|
| TICK-01 | P0 | List load | Open tickets tab | List loads; no blank screen | |
| TICK-02 | P1 | Filter by status/scope | Switch tabs | Correct tickets per scope | Tab highlight |
| TICK-03 | P1 | Search by guest/room | Enter query | Debounced filtered results | |
| TICK-04 | P0 | Detail view | Tap ticket | All metadata, timeline, guest info correct | |
| TICK-05 | P0 | Accept incoming + ETA | Open incoming → accept w/ ETA | Status → accepted/in-progress; timeline entry added | |
| TICK-06 | P0 | Mark done | Mark as done | Ticket completes; list updates | |
| TICK-07 | P1 | Add note | Submit note | Appears in timeline; no duplicates | |
| TICK-08 | P1 | Reassign | Change department | Department + assignee updated | |
| TICK-09 | P0 | Create universal | Universal flow → submit | Created and appears in list | Required-field enforcement |
| TICK-10 | P0 | Create catalog | Catalog flow w/ pricing | Created; pricing matches selection | |
| TICK-11 | P0 | Create manual | Manual flow → submit | Created | |
| TICK-12 | P1 | Missing required data | Blank submit | Specific per-field errors; no create call | |
| TICK-13 | P1 | API failure on create | Force 500 | Error UI; retry works; no orphan ticket | |
| TICK-14 | P1 | Realtime ticket update | Trigger external change | List updates; no duplicates or stale data | |
| TICK-15 | P1 | Long list performance | Scroll 200+ tickets | Smooth scroll; lazy load functional | See §16 |
| TICK-16 | P1 | Draft persistence on create | Start create → background app 30s → resume | Draft preserved (or explicit discard prompt) | New |
| TICK-17 | P2 | Attachments / images | Attach image to ticket | Uploads with progress; size limit enforced; thumbnail in detail | New — verify feature exists first |
| TICK-18 | P2 | Priority / SLA badge | Open ticket near SLA breach | Priority and SLA timer displayed; escalates correctly | New |
| TICK-19 | P2 | Escalation rules | Wait past SLA threshold | Ticket auto-escalates per backend rule; UI reflects new state | New |
| TICK-20 | P1 | Concurrent edit conflict | User A and User B edit same ticket | Last-write-wins or conflict toast, per spec; no silent data loss | New |
| TICK-21 | P1 | Offline create then reconnect | Create ticket offline (if supported) | Either disabled offline OR queued + synced on reconnect | New — confirm policy |
| TICK-22 | P2 | RBAC on actions | Login as restricted role | Restricted actions (reassign, mark done) hidden/disabled | New |
| TICK-23 | P2 | PII redaction | Inspect logs / screenshots in dev mode | No guest PII written to logs / crash reports | New |

---

## 11. Notifications (In-App Inbox)

| ID | Priority | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|---|
| NOTIF-01 | P0 | Open inbox | Tap bell | Sheet opens with unread count | Scrollable |
| NOTIF-02 | P0 | Foreground push | Send FCM while open | Foreground toast + inbox updates | |
| NOTIF-03 | P0 | Background push | Send FCM while backgrounded | System tray entry; tap deep-links correctly | |
| NOTIF-04 | P1 | Mark read | Mark item read | Item updates; badge decreases | |
| NOTIF-05 | P1 | Clear all | Use clear-all | Empties or empty state shown | BE/UI sync |
| NOTIF-06 | P0 | Deep link tap | Tap notification | Lands on correct ticket/page with context | |
| NOTIF-07 | P2 | Offline inbox | Open with no network | Cached items shown; graceful error otherwise | |
| NOTIF-08 | P1 | Unread badge realtime | Push arrives | Bell badge updates live | |
| NOTIF-09 | P1 | Reconciliation on resume | Background app → resume | Inbox reconciles missed events (no gaps, no dupes) | New |
| NOTIF-10 | P2 | Notification grouping / channels | Send multiple notifications fast | Grouped sensibly on Android channels / iOS threading | New |
| NOTIF-11 | P2 | Notification sound + vibration per channel | Trigger each category | Matches platform notification settings | New |
| NOTIF-12 | P2 | Quiet hours / DND respect | Enable DND | Pushes respect OS DND; in-app inbox still updates | New |

---

## 12. Profile

| ID | Priority | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|---|
| PROF-01 | P0 | View profile | Open profile | Name, email, hotel, subscription correct | |
| PROF-02 | P1 | Edit name | Edit → save | Persists locally + server | |
| PROF-03 | P1 | Avatar from gallery | Upload | Progress shown; new avatar visible | |
| PROF-04 | P1 | Avatar from camera | Upload | Permission prompt; upload works | |
| PROF-05 | P0 | Theme toggle | Toggle light/dark | Switches instantly; persisted (`app.themeMode`) | |
| PROF-06 | P0 | Language change | Pick locale | UI updates immediately; persisted (`app.locale`) | |
| PROF-07 | P0 | Logout | Logout + confirm | Session cleared | |
| PROF-08 | P2 | Invalid edit data | Bad input | Validation blocks request | |
| PROF-09 | P1 | Profile API failure | Force failure | Error + retry path | |
| PROF-10 | P2 | Avatar size/format limits | Upload >max size / unsupported format | Clear error; no crash | New |
| PROF-11 | P2 | Theme/locale survives logout-login | Toggle → logout → login | Restored on next session | New |

---

## 13. Activity Feed

| ID | Priority | Scenario | Steps | Expected Outcome | Notes |
|---|---|---|---|---|---|
| ACT-01 | P0 | Timeline load | Open tab | Events load, grouped by day | |
| ACT-02 | P1 | Event-type filter | Select | Only matching events | Persists while visible |
| ACT-03 | P1 | Department filter | Apply | Only relevant events | Combine filters supported |
| ACT-04 | P0 | Navigate from event | Tap row | Opens ticket detail; message if missing | |
| ACT-05 | P1 | Realtime event | Trigger new event | Appears live, no dupes | |
| ACT-06 | P2 | Empty state | No events | Clear empty UI | |
| ACT-07 | P1 | Scroll performance | Scroll fast | Smooth on long feed | See §16 |
| ACT-08 | P2 | Timezone correctness | Change device TZ | Timestamps render in correct local TZ | New |
| ACT-09 | P2 | Date format per locale | Switch locale | Date/number formatting respects locale | New |

---

## 14. Rooms / Catalog / FCM / Languages / Modules / Version / Shell

> Cases from v1 retained; additions below.

### 14.1 Rooms

| ID | Priority | Scenario | Notes |
|---|---|---|---|
| ROOM-01 | P1 | Room selection in ticket creation | v1 |
| ROOM-02 | P1 | Room context in tickets | v1 |
| ROOM-03 | P2 | No-room state | v1 |
| ROOM-04 | P2 | Room OOO/OOS state visibility | New |

### 14.2 FCM / Push

| ID | Priority | Scenario | Notes |
|---|---|---|---|
| FCM-01 | P0 | Initial token registration | v1 |
| FCM-02 | P1 | Token refresh | v1 |
| FCM-03 | P0 | iOS/Android permission flow | v1 |
| FCM-04 | P0 | Payload routing | v1 |
| FCM-05 | P0 | Terminated-state launch via push | v1 |
| FCM-06 | P2 | Notification permission revoked at runtime | New — surface in-app prompt + settings link |
| FCM-07 | P2 | Token rotation after app reinstall | New |

### 14.3 Languages / i18n

| ID | Priority | Scenario | Notes |
|---|---|---|---|
| LANG-01 | P0 | Change locale in profile | v1 |
| LANG-02 | P0 | Locale persists across restart | v1; key `app.locale` |
| LANG-03 | P1 | Fallback to system locale | v1 |
| LANG-04 | P1 | Translation coverage | v1; sweep ARB keys |
| LANG-05 | P2 | RTL layout (if supported) | New |
| LANG-06 | P1 | No hardcoded strings (UI/snackbars/dialogs/notifications) | Per CLAUDE.md i18n rule |

### 14.4 Modules placeholder

| ID | Priority | Scenario | Notes |
|---|---|---|---|
| MOD-01 | P2 | Coming-soon screen | v1 |
| MOD-02 | P3 | Placeholder under rotation | v1 |

### 14.5 Version Control

| ID | Priority | Scenario | Notes |
|---|---|---|---|
| VER-01 | P1 | Optional update prompt | v1 |
| VER-02 | P0 | Forced update gating | v1 |
| VER-03 | P1 | Up-to-date path | v1 |
| VER-04 | P1 | Version check once per session | v1 |
| VER-05 | P2 | App store link opens correct store per platform | New |

### 14.6 Shell / Navigation

| ID | Priority | Scenario | Notes |
|---|---|---|---|
| SHELL-01 | P0 | Bottom nav switching | v1 |
| SHELL-02 | P0 | Deep link routing (cold, warm, terminated) | v1 + verify all three states |
| SHELL-03 | P1 | Back stack across tabs | v1 |
| SHELL-04 | P1 | HomeShell resume stability | v1 |
| SHELL-05 | P2 | Tablet / landscape layout | New |
| SHELL-06 | P2 | Split-screen / multi-window (Android) | New |

---

## 15. Realtime / Socket Resilience

| ID | Priority | Scenario | Expected Outcome |
|---|---|---|---|
| RT-01 | P0 | Initial socket connect on login | Connection established; auth handshake succeeds |
| RT-02 | P0 | Reconnect after network drop | Exponential backoff; reconnects without manual action |
| RT-03 | P0 | Reconcile-on-reconnect | Missed events fetched via REST diff (no UI gaps, no dupes) |
| RT-04 | P1 | Reconcile on app resume from background | Same as RT-03 |
| RT-05 | P1 | Heartbeat / ping behaviour | No false disconnects on idle |
| RT-06 | P2 | Periodic poll fallback (last resort) | Only engages if socket unhealthy beyond threshold |
| RT-07 | P1 | Auth-failure on socket (expired token) | Triggers token refresh and reconnect |

---

## 16. Performance & Stability Benchmarks

| ID | Priority | Metric | Target | Method |
|---|---|---|---|---|
| PERF-01 | P1 | Cold start to first interactable frame | ≤ 2.5s mid-tier Android, ≤ 2s iPhone | Stopwatch + Flutter DevTools |
| PERF-02 | P1 | Dashboard first paint after auth | ≤ 1s with cached data, ≤ 2s cold | DevTools timeline |
| PERF-03 | P1 | Screen transition jank | < 1% frames > 16ms | DevTools |
| PERF-04 | P2 | Memory after 30 min usage | No upward leak trend | DevTools memory tab |
| PERF-05 | P1 | Network loss resilience | Graceful errors; recovery on reconnect | Charles offline toggle |
| PERF-06 | P1 | API 5xx handling | Friendly error + retry on critical calls | Charles rewrite rules |
| PERF-07 | P2 | Offline cache fallback | Stale-data indicator shown | |
| PERF-08 | P0 | No crashes during smoke run | Zero crashes across full P0 pass | Crashlytics |
| PERF-09 | P0 | Session expiry | Clean re-login prompt, no unauthorised access | |
| PERF-10 | P1 | Localization completeness | No missing strings; no overflow in `es` | Visual sweep + ARB diff |

---

## 17. Accessibility (A11y)

| ID | Priority | Scenario | Expected Outcome |
|---|---|---|---|
| A11Y-01 | P1 | TalkBack / VoiceOver labels on primary actions | All interactive elements announced meaningfully |
| A11Y-02 | P1 | Dynamic text scale 130% | Layouts adapt without clipping/overflow |
| A11Y-03 | P2 | Color contrast (WCAG AA) | Text vs background passes AA |
| A11Y-04 | P2 | Focus order with external keyboard (iPad) | Logical focus traversal |
| A11Y-05 | P2 | Tap target size ≥ 44×44 pt | Verified on key actions |

---

## 18. Security & Privacy

| ID | Priority | Scenario | Expected Outcome |
|---|---|---|---|
| SEC-01 | P0 | Tokens stored in secure storage (Keychain/Keystore) | Not in shared prefs / logs |
| SEC-02 | P0 | TLS only; no cleartext traffic | Verified via `networkSecurityConfig` / ATS |
| SEC-03 | P1 | Auth headers redacted in logs | No bearer tokens in Crashlytics/logcat |
| SEC-04 | P1 | Deep link target validation | Malformed / external links rejected |
| SEC-05 | P1 | Backgrounded app blurs sensitive screens (iOS app switcher) | If feature shipped, verify; else flag as known gap |
| SEC-06 | P2 | Clipboard hygiene for guest PII | Sensitive fields don't auto-copy |
| SEC-07 | P1 | Logout invalidates server session | Old token rejected on next call |
| SEC-08 | P1 | Crash reports contain no PII | Manual inspection of recent Crashlytics events |

---

## 19. Observability

| ID | Priority | Scenario | Expected Outcome |
|---|---|---|---|
| OBS-01 | P1 | Crashlytics receives crashes | Force-crash dev build; entry appears |
| OBS-02 | P2 | Analytics events fire for key actions | login, ticket_create, ticket_complete, push_open |
| OBS-03 | P2 | Performance traces (cold start, ticket list) | Visible in Firebase Performance |
| OBS-04 | P2 | Structured logs (no PII) | Log review on a sample session |

---

## 20. Regression Suite (Smoke — must pass every build)

Run this short list on every build before deeper UAT:

`AUTH-01`, `AUTH-06`, `AUTH-07`, `DASH-01`, `DASH-02`, `DASH-04`, `TICK-01`, `TICK-04`, `TICK-05`, `TICK-06`, `TICK-09`, `NOTIF-01`, `NOTIF-03`, `NOTIF-06`, `PROF-05`, `PROF-06`, `FCM-01`, `FCM-04`, `LANG-01`, `VER-02`, `SHELL-01`, `RT-01`, `RT-03`, `PERF-08`.

**Smoke target:** complete in ≤ 60 minutes on one Android + one iOS device.

---

## 21. Traceability Matrix (Requirement → Test)

| Requirement | Covered by |
|---|---|
| R-AUTH: Secure login + session persistence | AUTH-01..14, SEC-01, SEC-07 |
| R-DASH: Live KPIs + needs attention | DASH-01..10, RT-04 |
| R-TICK: Full ticket lifecycle | TICK-01..23, RT-03 |
| R-NOTIF: Inbox + push | NOTIF-01..12, FCM-01..07 |
| R-PROF: Profile + preferences | PROF-01..11, LANG-01..06 |
| R-ACT: Activity feed | ACT-01..09 |
| R-VER: Update gating | VER-01..05 |
| R-A11Y: Accessibility baseline | A11Y-01..05 |
| R-SEC: Security & privacy | SEC-01..08 |
| R-OBS: Observability | OBS-01..04 |

Update this table whenever a requirement is added or retired.

---

## 22. Sign-off

UAT is complete when the following sign off in writing (email or PR comment):

| Role | Name | Date | Decision |
|---|---|---|---|
| QA Lead | | | Pass / Fail |
| Dev Lead | | | Pass / Fail |
| PM | | | Pass / Fail |
| Stakeholder | | | Pass / Fail |

Attach: execution sheet (per-case Pass/Fail per device/locale), open-defect list with severity & owner, performance benchmark capture.

---

## 23. Gaps & Open Questions (to confirm before UAT starts)

The following items in v1 were ambiguous; confirm with product before execution:

1. **Concurrent login policy** (AUTH-10) — allow or invalidate?
2. **Offline ticket create** (TICK-21) — disabled or queued?
3. **Concurrent edit conflict** (TICK-20) — last-write-wins, lock, or merge?
4. **Attachments** (TICK-17) — supported in this release?
5. **Biometric auth** (AUTH-12) — in scope?
6. **RTL support** (LANG-05) — required for current locales?
7. **Backgrounded-screen blur for PII** (SEC-05) — implemented?

---

## 24. Change Log

| Version | Date | Author | Notes |
|---|---|---|---|
| v1 | (existing) | — | Initial test plan in `UAT_TEST_PLAN.md` |
| v2 | 2026-06-03 | QA Lead | Expanded to full QA handbook: env, RACI, severity, exit criteria, traceability, accessibility, security, observability, realtime resilience, and ~40 new test cases |

---

## Appendix A — Converting this document to PDF

Use any of the methods in `CONVERT_TO_PDF.md`. Quickest:

```bash
# From repo root
pandoc docs/UAT_TEST_PLAN_v2.md \
  -o docs/UAT_TEST_PLAN_v2.pdf \
  --from gfm \
  --pdf-engine=xelatex \
  -V geometry:margin=0.7in \
  -V mainfont="Helvetica"
```

If `pandoc` / LaTeX is unavailable, use VS Code's **Markdown PDF** extension (right-click → Export PDF) or the Node script at `scripts/`.
