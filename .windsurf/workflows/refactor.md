---
description: Refactor code to improve quality without changing behavior
---

# Refactor Workflow

## Goal
Improve code quality WITHOUT changing behavior.

## Step 1: Identify Problems
- Find duplicate code
- Identify architectural violations
- Locate hardcoded values
- Find non-reusable components
- Note readability issues

## Step 2: Plan Refactoring
- Extract reusable components
- Apply proper architecture
- Remove duplication
- Improve naming
- Enforce base layer usage

## Step 3: Implement Changes
- Make incremental changes
- Extract to base managers where appropriate
- Follow feature-first architecture
- Maintain separation of concerns
- Use proper Riverpod patterns

## Step 4: Verify
- Ensure no functionality changed
- Test all affected areas
- Confirm architecture compliance

## Output
1. Problems identified
2. Refactored code
3. Before vs After explanation

## Rules
- Do NOT change functionality
- Do NOT introduce new bugs
- Follow project principles
- Use base layer managers
