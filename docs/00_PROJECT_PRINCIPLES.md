# Project Principles

## Purpose
Defines the fundamental philosophy of the project. Every decision must align with these principles.

## How to Use
- ALWAYS read this before implementing any feature
- If a decision conflicts with these principles → STOP and rethink

## Core Principles

1. No "vibe coding" — every change must be:
   - Understandable
   - Reviewable
   - Testable

2. Separation of Concerns:
   - UI = rendering only
   - ViewModel = state + orchestration
   - Domain = business logic
   - Data = API, storage

3. DRY (Don't Repeat Yourself):
   - Extract reusable components early

4. Predictability:
   - No hidden logic in widgets

5. Scalability:
   - Feature-first architecture

6. Explicit over implicit:
   - No magic logic

7. Test-first mindset:
   - All logic must be testable