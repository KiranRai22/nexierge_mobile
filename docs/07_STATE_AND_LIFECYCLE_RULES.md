# State and Lifecycle Rules

## Purpose
Ensures predictable state management and lifecycle handling.

## How to Use
- Apply this when designing any state or provider

## Rules

- Single source of truth
- Immutable state

## Lifecycle

- Use autoDispose for temporary state
- Use keepAlive for persistent state

## Async Handling

- Always use AsyncValue
- Avoid manual loading flags

## Realtime

- Integrate streams into AsyncNotifier
- Keep state reactive