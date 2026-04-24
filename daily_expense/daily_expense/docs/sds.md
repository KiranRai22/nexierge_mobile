# Software Design Specification (SDS) for Daily Expense Tracker

## 1. Introduction
This Software Design Specification (SDS) details the design of the Daily Expense Tracker mobile application based on the SRS. The design follows MVVM architecture using FilledStack (Stacked package) for state management and dependency injection, ensuring separation of concerns, testability, and adherence to Flutter best practices as per `.github/instructions/code_rules.instructions.md`.

### 1.1 Purpose
To provide a technical blueprint for implementing the MVP features: expense entry, budgets, and reports.

### 1.2 Scope
Covers system architecture, data design, interface design, and component design for the MVP. Advanced features are deferred.

### 1.3 References
- SRS: `docs/srs.md`
- Coding Rules: `.github/instructions/code_rules.instructions.md`
- FilledStack Docs: https://pub.dev/packages/stacked

## 2. System Architecture
The app uses a layered architecture:
- **Presentation Layer**: Views (UI) bound to ViewModels.
- **Domain Layer**: ViewModels (business logic), Models (data structures).
- **Data Layer**: Repositories and services for data access.

FilledStack manages state reactively with streams and dependency injection via a service locator.

### High-Level Architecture Diagram
[Link to Diagram: docs/diagrams/architecture_diagram.png]  
Description: Views connect to ViewModels, which use Repositories for data. FilledStack locator provides services.

## 3. Data Design
Data is stored locally using Hive for key-value storage.

### Entity Models
- **Expense**: {id: String, amount: double, category: String, date: DateTime, notes: String}
- **Budget**: {id: String, category: String, limit: double, spent: double}

### Database Schema
- Expenses Box: Stores Expense objects.
- Budgets Box: Stores Budget objects.

## 4. Interface Design
UI follows Material Design with responsive layouts.

### Wireframes
- [Expense Entry Screen: docs/wireframes/expense_entry.png] - Form with fields for amount, category, date, notes.
- [Budgets Screen: docs/wireframes/budgets.png] - List of budgets with progress bars.
- [Reports Screen: docs/wireframes/reports.png] - Charts and summaries.

Navigation uses FilledStack's routing for screen transitions.

## 5. Component Design
- **ViewModels**: Extend BaseViewModel; handle logic, data fetching, and UI state.
- **Views**: Extend BaseView; bind to ViewModels for reactive updates.
- **Repositories**: Abstract data access; implement CRUD operations.
- **Services**: Handle external concerns like storage initialization.

### Sequence Diagram for Expense Entry
[Link to Diagram: docs/diagrams/expense_entry_sequence.png]  
Description: User inputs data -> ViewModel validates -> Repository saves -> UI updates.

## 6. Deployment Design
- Platform: iOS/Android via Flutter.
- Packaging: Standard Flutter build process.
- No backend for MVP; local-only.

## 7. Appendices
- [Class Diagram: docs/diagrams/class_diagram.png] - MVVM classes and relationships.
- Security Notes: Local encryption using Hive adapters.