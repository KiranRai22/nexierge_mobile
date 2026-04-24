# API and Realtime Rules

## Purpose
Standardizes communication with backend, WebSocket, and Firebase.

## How to Use
- All data must flow through repository layer

## API Rules

- Use repository pattern
- Map DTO → Domain model
- Handle errors centrally

## WebSocket Rules

- Use WebSocketService
- Handle reconnect
- Manage lifecycle properly

## Firebase Auth

- Wrap inside AuthService
- Never call Firebase directly in UI

## Push Notifications

- Use NotificationService
- Handle foreground/background

## Local Storage

- Use StorageService abstraction

## Restrictions

- No raw JSON in UI
- No direct API calls in UI