# Riverpod Guidelines

## Purpose
Standardizes how state management is implemented using Riverpod.

## How to Use
- Choose provider type based on use-case
- Follow naming and lifecycle rules

## Provider Selection Guide

| Use Case | Provider |
|--------|--------|
| Dependency Injection | Provider |
| Simple UI state | StateProvider |
| Complex sync logic | Notifier |
| Async / API / realtime | AsyncNotifier |

## Rules

1. AsyncNotifier is DEFAULT for API/data
2. Avoid FutureProvider for complex logic
3. UI must only use ref.watch
4. Use ref.read for actions
5. Use ref.listen for side effects (navigation)

## Naming

<feature><Type>Provider

Example:
authNotifierProvider

## State Rules

- Immutable state only
- Use copyWith
- Single source of truth