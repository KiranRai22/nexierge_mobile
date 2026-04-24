# Base Layer Rules

## Purpose
Prevents duplication by centralizing shared logic and design system.

## How to Use
- ALWAYS check here before creating new logic or UI
- Extend existing managers instead of duplicating

## Required Base Modules

1. ConstantManager → All constants
2. ThemeManager → ThemeData
3. ColorPalette → Colors
4. TypographyManager → Fonts & styles
5. WidgetManager → Reusable widgets
6. APIEndpoints → All endpoints
7. EnumManager → Enums
8. StringUtils → String operations
9. ResponsiveManager → Layout scaling
10. ErrorHandler → Centralized error handling

## Rules

- No hardcoded values allowed
- No duplicate styles
- No repeated widgets

## Example

❌ Wrong:
TextStyle(fontSize: 16)

✅ Correct:
TypographyManager.bodyMedium