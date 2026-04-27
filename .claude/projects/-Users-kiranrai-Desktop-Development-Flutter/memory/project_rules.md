---
name: Project Engineering Rules
description: Core rules from all docs/0X_ files that must be followed for every fix, feature, and review
type: project
---

# Project Rules Summary (from docs/)

## Architecture (01)
- Feature-first: `lib/features/<name>/{data,domain,presentation}/`
- Dependency flow: UI → ViewModel → Repository → DataSource
- UI must NEVER call API directly or contain business logic
- Notifiers must NOT contain UI logic; repository must be abstracted

## Riverpod (02)
- AsyncNotifier is DEFAULT for API/async; avoid FutureProvider for complex logic
- `ref.watch` in UI only; `ref.read` for actions; `ref.listen` for side effects
- Naming: `<feature><Type>Provider` e.g. `authNotifierProvider`
- Immutable state only, use `copyWith`, single source of truth

## Base Layer (04)
- Use ConstantManager, ThemeManager, ColorPalette, TypographyManager, WidgetManager, APIEndpoints, EnumManager, StringUtils, ResponsiveManager, ErrorHandler
- No hardcoded values, no duplicate styles, no repeated widgets
- Always check existing base modules before creating new code

## UI (05)
- Spacing scale: 4, 8, 16, 24
- No hardcoded colors, no inline styles, no layout hacks
- Support small/medium/large phone + tablet
- Use Cupertino where needed (iOS)

## API & Realtime (06)
- All data flows through repository layer
- Map DTO → Domain model; handle errors centrally
- WebSocketService for WebSocket; AuthService wraps Firebase; NotificationService for push; StorageService for local
- No raw JSON in UI, no direct API calls in UI

## State & Lifecycle (07)
- Single source of truth; immutable state
- autoDispose for temporary state; keepAlive for persistent
- Always use AsyncValue; avoid manual loading flags
- Integrate streams into AsyncNotifier

## Testing (08)
- All ViewModels must be testable; repositories must be mockable
- Unit tests for logic, Widget tests for UI
- Small commits, clear messages

## Agent Workflow (09)
Step 1: Understand → Step 2: Plan → Step 3: Implement → Step 4: Explain → Step 5: Improve
- Never rewrite working code without reason

## DOs and DON'Ts (10)
DO: modular code, correct Riverpod, reuse components, keep logic testable
DON'T: logic in widgets, hardcoded values, duplicate code, ignore responsiveness, global mutable state

## PR Auto-Reject Conditions
- Logic inside widgets
- Direct API calls from UI
- Duplicate components
- Hardcoded styles
