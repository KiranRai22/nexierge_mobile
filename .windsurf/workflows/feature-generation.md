---
description: Generate new features following clean architecture and Riverpod patterns
---

# Feature Generation Workflow

You are a senior Flutter architect implementing a new feature.

## Context
- State management: Riverpod (AsyncNotifier preferred)
- Architecture: Feature-first + Clean Architecture
- No business logic in UI
- No direct API calls from UI

## Step 1: Understand Requirements
- Read the feature description
- Identify required layers (presentation, domain, data)
- Check for existing reusable components

## Step 2: Plan Architecture
- Decide on provider types (AsyncNotifier for async logic)
- Identify repository pattern needs
- Check base managers for reusable components

## Step 3: Implement Data Layer
- Create repository interfaces and implementations
- Implement API/data sources
- Map DTOs to domain models
- Handle errors centrally

## Step 4: Implement Domain Layer
- Create domain entities
- Implement business logic
- Define use cases if needed

## Step 5: Implement Presentation Layer
- Create AsyncNotifier for state management
- Build UI components using ThemeManager, ColorPalette, TypographyManager
- No hardcoded styles
- No inline business logic

## Step 6: Output Format
1. File structure first
2. Full code per file
3. Explanation of decisions

## Constraints
- Follow architecture strictly: presentation/domain/data
- Use AsyncNotifier for async logic
- Use repository pattern
- Immutable state
- No shortcuts
- No placeholder logic unless specified
- Check existing base managers before creating new code
