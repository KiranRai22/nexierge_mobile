import 'package:flutter/material.dart';

import 'color_palette.dart';
import 'typography_manager.dart';

abstract class ThemeManager {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: ColorPalette.primary,
          onPrimary: ColorPalette.textOnPrimary,
          secondary: ColorPalette.secondary,
          onSecondary: ColorPalette.textOnPrimary,
          error: ColorPalette.error,
          surface: ColorPalette.surfaceLight,
          onSurface: ColorPalette.textPrimary,
        ),
        scaffoldBackgroundColor: ColorPalette.backgroundLight,
        textTheme: _textTheme,
        appBarTheme: _appBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        cardTheme: _cardTheme,
        dividerTheme: const DividerThemeData(
          color: ColorPalette.divider,
          thickness: 1,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: ColorPalette.primaryLight,
          onPrimary: ColorPalette.textOnPrimary,
          secondary: ColorPalette.secondaryLight,
          onSecondary: ColorPalette.textOnPrimary,
          error: ColorPalette.error,
          surface: ColorPalette.surfaceDark,
          onSurface: ColorPalette.textOnDark,
        ),
        scaffoldBackgroundColor: ColorPalette.backgroundDark,
        textTheme: _textTheme,
        appBarTheme: _appBarTheme.copyWith(
          backgroundColor: ColorPalette.surfaceDark,
          foregroundColor: ColorPalette.textOnDark,
        ),
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        cardTheme: _cardTheme,
        dividerTheme: const DividerThemeData(
          color: ColorPalette.grey700,
          thickness: 1,
        ),
      );

  static TextTheme get _textTheme => TextTheme(
    displayLarge: TypographyManager.displayLarge,
    displayMedium: TypographyManager.displayMedium,
    displaySmall: TypographyManager.displaySmall,
    headlineLarge: TypographyManager.headlineLarge,
    headlineMedium: TypographyManager.headlineMedium,
    headlineSmall: TypographyManager.headlineSmall,
    titleLarge: TypographyManager.titleLarge,
    titleMedium: TypographyManager.titleMedium,
    titleSmall: TypographyManager.titleSmall,
    bodyLarge: TypographyManager.bodyLarge,
    bodyMedium: TypographyManager.bodyMedium,
    bodySmall: TypographyManager.bodySmall,
    labelLarge: TypographyManager.labelLarge,
    labelMedium: TypographyManager.labelMedium,
    labelSmall: TypographyManager.labelSmall,
  );

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: ColorPalette.primary,
    foregroundColor: ColorPalette.textOnPrimary,
    elevation: 0,
    centerTitle: true,
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorPalette.primary,
      foregroundColor: ColorPalette.textOnPrimary,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: TypographyManager.labelLarge,
      elevation: 0,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ColorPalette.primary,
      minimumSize: const Size.fromHeight(48),
      side: const BorderSide(color: ColorPalette.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TypographyManager.labelLarge,
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ColorPalette.primary,
      textStyle: TypographyManager.labelLarge,
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: ColorPalette.inputBackground,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ColorPalette.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ColorPalette.error),
    ),
    hintStyle: TypographyManager.bodyMedium
        .copyWith(color: ColorPalette.textSecondary),
    labelStyle: TypographyManager.bodyMedium,
    errorStyle:
        TypographyManager.bodySmall.copyWith(color: ColorPalette.error),
  );

  static final CardThemeData _cardTheme = CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: ColorPalette.surfaceLight,
    margin: EdgeInsets.zero,
  );
}
