---
description: Convert Figma designs to pixel-perfect Flutter UI
---

# Figma to Flutter Workflow

## Input
Figma design description or screenshot

## Step 1: Analyze Design
- Break down layout structure
- Identify spacing and alignment
- Note typography styles
- Identify color palette
- Identify reusable components

## Step 2: Plan Layout
- Use spacing scale (4, 8, 16, 24)
- Plan responsive breakpoints
- Identify widget hierarchy
- Check for existing reusable widgets

## Step 3: Implement UI
- Match EXACT spacing from Figma
- Match EXACT typography from Figma
- Match EXACT colors from Figma
- Use ThemeManager for colors
- Use TypographyManager for fonts
- Extract reusable widgets

## Step 4: Ensure Responsiveness
- Small phone support
- Medium phone support
- Large phone support
- Tablet support
- Avoid overflow issues

## Output
1. Layout breakdown
2. Widget tree
3. Full code

## Rules
- No hardcoded colors
- Use ThemeManager & TypographyManager
- Extract reusable widgets
- Pixel-perfect implementation
- Exact spacing and alignment
