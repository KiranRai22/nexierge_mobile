---
description: Review pull requests against project standards and architecture rules
---

# PR Review Checklist

## 🔴 MUST PASS (Blocker)

### Architecture
- No business logic in UI
- Proper separation (presentation/domain/data)
- Repository pattern followed

### State Management
- Correct provider type used
- No multiple sources of truth
- Async handled with AsyncValue

### Code Quality
- No duplicate code
- No hardcoded values
- Functions single responsibility

### UI
- Uses ThemeManager
- Responsive on all devices
- No overflow issues

### Reusability
- Common widgets extracted
- No repeated styles

## 🟡 SHOULD PASS

- Code is readable
- Naming is clear
- File size < 300 lines

## 🟢 BONUS

- Unit tests added
- Edge cases handled
- Performance considered

## ❌ AUTO REJECT IF

- Logic inside widgets
- Direct API calls from UI
- Duplicate components
- Hardcoded styles

## Review Process
1. Check all MUST PASS items
2. Review SHOULD PASS items
3. Note BONUS items
4. Reject if any AUTO REJECT conditions met
