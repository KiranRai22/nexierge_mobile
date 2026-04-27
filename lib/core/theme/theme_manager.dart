import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_shadows.dart';
import 'color_palette.dart';
import 'typography_manager.dart';

/// Light + dark `ThemeData` for the app.
///
/// Both themes:
/// 1. Install `AppColors`, `AppRadii`, `AppShadows` extensions so widgets
///    can read the Medusa tokens via `context.appColors.*` etc.
/// 2. Derive the Material 3 `ColorScheme`, `scaffoldBackgroundColor`,
///    `cardTheme`, `dialogTheme`, `snackBarTheme`, `appBarTheme`,
///    `dividerTheme`, and `bottomSheetTheme` from those tokens — so even
///    Material defaults (AlertDialog, ListTile, SnackBar, etc.) flip
///    correctly when the user toggles light/dark.
///
/// The legacy `ColorPalette.primary` is preserved as the brand colour for
/// `ElevatedButton` / outlined / text button defaults so existing CTAs
/// (login, logout) keep their look during the migration.
abstract class ThemeManager {
  static ThemeData get lightTheme => _build(brightness: Brightness.light);
  static ThemeData get darkTheme => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final shadows = isDark ? AppShadows.dark : AppShadows.light;
    const radii = AppRadii.standard;

    final colorScheme = ColorScheme(
      brightness: brightness,
      // Brand primary stays on the legacy `ColorPalette.primary` so existing
      // pink CTAs (logout, login button) keep working without per-widget
      // overrides. New work should read explicit AppColors tokens.
      primary: ColorPalette.primary,
      onPrimary: colors.fgOnColor,
      secondary: colors.bgInteractive,
      onSecondary: colors.fgOnColor,
      error: colors.fgError,
      onError: colors.fgOnColor,
      surface: colors.bgBase,
      onSurface: colors.fgBase,
      surfaceContainerHighest: colors.bgComponent,
      surfaceContainerHigh: colors.bgComponent,
      surfaceContainer: colors.bgComponent,
      surfaceContainerLow: colors.bgSubtle,
      surfaceContainerLowest: colors.bgSubtle,
      onSurfaceVariant: colors.fgSubtle,
      outline: colors.borderStrong,
      outlineVariant: colors.borderBase,
      shadow: const Color(0xFF000000),
      scrim: colors.bgOverlay,
      inverseSurface: colors.contrastBgBase,
      onInverseSurface: colors.contrastFgPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bgSubtle,
      canvasColor: colors.bgBase,
      textTheme: _textTheme(colors),
      iconTheme: IconThemeData(color: colors.fgBase, size: 20),
      primaryIconTheme: IconThemeData(color: colors.fgBase, size: 20),
      dividerTheme: DividerThemeData(color: colors.borderBase, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        foregroundColor: colors.fgBase,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.fgBase),
        titleTextStyle: TypographyManager.textHeading.copyWith(
          color: colors.fgBase,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
          side: BorderSide(color: colors.borderBase),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
        ),
        titleTextStyle: TypographyManager.textHeading.copyWith(
          color: colors.fgBase,
        ),
        contentTextStyle: TypographyManager.textBody.copyWith(
          color: colors.fgSubtle,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.contrastBgBase,
        contentTextStyle: TypographyManager.textBody.copyWith(
          color: colors.contrastFgPrimary,
        ),
        actionTextColor: colors.fgInteractive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.bgBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radii.xl),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.bgBase,
        selectedItemColor: colors.fgInteractive,
        unselectedItemColor: colors.fgMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.bgBase,
        indicatorColor: colors.bgHighlight,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.fgSubtle,
        textColor: colors.fgBase,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.fgInteractive,
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme(colors),
      textButtonTheme: _textButtonTheme(colors),
      inputDecorationTheme: _inputDecorationTheme(colors, radii),
      extensions: <ThemeExtension<dynamic>>[colors, radii, shadows],
    );
  }

  static TextTheme _textTheme(AppColors colors) => TextTheme(
        displayLarge:
            TypographyManager.displayLarge.copyWith(color: colors.fgBase),
        displayMedium:
            TypographyManager.displayMedium.copyWith(color: colors.fgBase),
        displaySmall:
            TypographyManager.displaySmall.copyWith(color: colors.fgBase),
        headlineLarge:
            TypographyManager.headlineLarge.copyWith(color: colors.fgBase),
        headlineMedium:
            TypographyManager.headlineMedium.copyWith(color: colors.fgBase),
        headlineSmall:
            TypographyManager.headlineSmall.copyWith(color: colors.fgBase),
        titleLarge: TypographyManager.titleLarge.copyWith(color: colors.fgBase),
        titleMedium:
            TypographyManager.titleMedium.copyWith(color: colors.fgBase),
        titleSmall: TypographyManager.titleSmall.copyWith(color: colors.fgBase),
        bodyLarge: TypographyManager.bodyLarge.copyWith(color: colors.fgBase),
        bodyMedium: TypographyManager.bodyMedium.copyWith(color: colors.fgBase),
        bodySmall:
            TypographyManager.bodySmall.copyWith(color: colors.fgSubtle),
        labelLarge: TypographyManager.labelLarge.copyWith(color: colors.fgBase),
        labelMedium:
            TypographyManager.labelMedium.copyWith(color: colors.fgBase),
        labelSmall:
            TypographyManager.labelSmall.copyWith(color: colors.fgSubtle),
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

  static OutlinedButtonThemeData _outlinedButtonTheme(AppColors c) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.fgInteractive,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: c.borderStrong),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TypographyManager.labelLarge,
        ),
      );

  static TextButtonThemeData _textButtonTheme(AppColors c) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.fgInteractive,
          textStyle: TypographyManager.labelLarge,
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(
    AppColors c,
    AppRadii r,
  ) =>
      InputDecorationTheme(
        filled: true,
        fillColor: c.bgField,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.md),
          borderSide: BorderSide(color: c.borderBase),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.md),
          borderSide: BorderSide(color: c.borderBase),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.md),
          borderSide: BorderSide(color: c.borderInteractive, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.md),
          borderSide: BorderSide(color: c.borderError),
        ),
        hintStyle: TypographyManager.textBody.copyWith(color: c.fgMuted),
        labelStyle: TypographyManager.textLabel.copyWith(color: c.fgSubtle),
        errorStyle: TypographyManager.textCaption.copyWith(color: c.fgError),
      );
}
