# Architecture Rules

## Purpose
Defines how the project is structured and how data flows.

## How to Use
- Before creating ANY new file, check where it belongs
- Follow dependency direction strictly

## Structure

lib/
  core/
  features/
  shared/

## Feature Structure

feature_name/
  data/
  domain/
  presentation/

## Responsibilities

### Presentation
- UI + Riverpod Notifiers

### Domain
- Business logic + entities

### Data
- API, storage, repository implementation

## Rules

- UI must NEVER call API directly
- UI must NEVER contain business logic
- Notifiers must NOT contain UI logic
- Repository must be abstracted

## Dependency Flow

UI → ViewModel → Repository → DataSource

❌ Forbidden:
UI → API
UI → Repository