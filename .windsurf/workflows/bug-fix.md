---
description: Debug and fix production bugs following minimal change principles
---

# Bug Fix Workflow

You are debugging a production Flutter app using Riverpod.

## Step 1: Identify Root Cause
- Analyze the bug description and code
- Trace the issue through the architecture layers
- Identify the exact location and cause of the bug

## Step 2: Apply Minimal Fix
- Do NOT rewrite entire code
- Fix minimal surface area
- Make the smallest possible change that resolves the issue

## Step 3: Output Format
1. Root cause explanation
2. Exact fix (diff style preferred)
3. Why this fix works
4. Any side effects

## Step 4: Verify
- No assumptions without stating them
- No breaking architecture
- Fix aligns with project principles

## Rules
- Identify root cause FIRST before making changes
- No assumptions without stating them
- No breaking architecture
- Minimal surface area changes only
