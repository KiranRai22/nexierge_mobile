# Feature Generation Prompt

You are a senior Flutter architect.

## Context
- State management: Riverpod (AsyncNotifier preferred)
- Architecture: Feature-first + Clean Architecture
- No business logic in UI
- No direct API calls from UI

## Task
Implement the following feature:

[DESCRIBE FEATURE]

## Requirements

1. Follow architecture strictly:
   - presentation/
   - domain/
   - data/

2. Use:
   - AsyncNotifier for async logic
   - Repository pattern
   - Immutable state

3. Reusability:
   - Check existing base managers before creating new code
   - Avoid duplication

4. UI:
   - No hardcoded styles
   - Use ThemeManager, ColorPalette, TypographyManager

5. Output format:
   - File structure first
   - Then full code per file
   - Then explanation

## Constraints

- No shortcuts
- No inline business logic
- No placeholder logic unless specified

## After implementation

Explain:
- Why this structure was used
- Possible improvements