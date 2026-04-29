import 'package:flutter/material.dart';

import 'app_colors.dart';
export 'app_colors.dart';

/// Unified theme manager containing all color definitions for the application.
/// This replaces both AppColors and ColorPalette with a single source of truth.
abstract class UnifiedThemeManager {
  // ---------------------------------------------------------------------------
  // Brand Colors
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryLight = Color(0xFFFCE4EC);
  static const Color primaryDark = Color(0xFFAD1457);
  static const Color primarySoftTint = Color(0xFFFDE8F1);

  static const Color secondary = Color(0xFF34A853);
  static const Color secondaryLight = Color(0xFF66BB6A);
  static const Color secondaryDark = Color(0xFF1B5E20);

  static const Color accent = Color(0xFFFBBC04);
  static const Color accentLight = Color(0xFFFFE082);
  static const Color accentDark = Color(0xFFF57F17);

  // ---------------------------------------------------------------------------
  // Semantic Colors
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFEA4335);
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color info = Color(0xFF1A73E8);

  // ---------------------------------------------------------------------------
  // HotelOps Brand Colors
  // ---------------------------------------------------------------------------
  static const Color opsPurple = Color(0xFF7B5CFF);
  static const Color opsPurpleDark = Color(0xFF5C3BE5);
  static const Color opsPurpleTint = Color(0xFFEFE8FF);
  static const Color opsPurpleSoft = Color(0xFFF6F1FF);

  // ---------------------------------------------------------------------------
  // Light Theme Colors
  // ---------------------------------------------------------------------------
  static const Color lightBgBase = Color(0xFFFFFFFF);
  static const Color lightBgBaseHover = Color(0xFFF4F4F5);
  static const Color lightBgBasePressed = Color(0xFFE4E4E7);
  static const Color lightBgSubtle = Color(0xFFFAFAFA);
  static const Color lightBgSubtleHover = Color(0xFFF4F4F5);
  static const Color lightBgSubtlePressed = Color(0xFFE4E4E7);
  static const Color lightBgComponent = Color(0xFFFAFAFA);
  static const Color lightBgComponentHover = Color(0xFFF4F4F5);
  static const Color lightBgComponentPressed = Color(0xFFE4E4E7);
  static const Color lightBgField = Color(0xFFFAFAFA);
  static const Color lightBgFieldHover = Color(0xFFF4F4F5);
  static const Color lightBgFieldComponent = Color(0xFFFFFFFF);
  static const Color lightBgFieldComponentHover = Color(0xFFFAFAFA);
  static const Color lightBgDisabled = Color(0xFFF4F4F5);
  static const Color lightBgHover = Color(0xFFF4F4F5);
  static const Color lightBgInteractive = Color(0xFF3B82F6);
  static const Color lightBgHighlight = Color(0xFFEFF6FF);
  static const Color lightBgHighlightHover = Color(0xFFDBEAFE);
  static const Color lightBgOverlay = Color(0xFF18181B);
  static const double lightBgOverlayAlpha = 0.4;
  static const Color lightBgSwitchOff = Color(0xFFE4E4E7);
  static const Color lightBgSwitchOffHover = Color(0xFFD4D4D8);

  static const Color lightFgBase = Color(0xFF18181B);
  static const Color lightFgSubtle = Color(0xFF52525B);
  static const Color lightFgMuted = Color(0xFF71717A);
  static const Color lightFgDisabled = Color(0xFFA1A1AA);
  static const Color lightFgOnColor = Color(0xFFFFFFFF);
  static const Color lightFgOnInverted = Color(0xFFFFFFFF);
  static const Color lightFgInteractive = Color(0xFF3B82F6);
  static const Color lightFgInteractiveHover = Color(0xFF2563EB);
  static const Color lightFgError = Color(0xFFE11D48);

  static const Color lightBorderBase = Color(0xFFE4E4E7);
  static const Color lightBorderStrong = Color(0xFFD4D4D8);
  static const Color lightBorderInteractive = Color(0xFF3B82F6);
  static const Color lightBorderError = Color(0xFFE11D48);
  static const Color lightBorderDanger = Color(0xFFBE123C);
  static const Color lightBorderMenuTop = Color(0xFFE4E4E7);
  static const Color lightBorderMenuBot = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Dark Theme Colors
  // ---------------------------------------------------------------------------
  static const Color darkBgBase = Color(0xFF1A1A1E);
  static const Color darkBgBaseHover = Color(0xFF222226);
  static const Color darkBgBasePressed = Color(0xFF2C2C32);
  static const Color darkBgSubtle = Color(0xFF0E0E11);
  static const Color darkBgSubtleHover = Color(0xFF16161A);
  static const Color darkBgSubtlePressed = Color(0xFF1E1E22);
  static const Color darkBgComponent = Color(0xFF222226);
  static const Color darkBgComponentHover = Color(0xFF3F3F46);
  static const Color darkBgComponentPressed = Color(0xFF52525B);
  static const Color darkBgField = Color(0xFF37373C);
  static const Color darkBgFieldHover = Color(0xFF424248);
  static const Color darkBgFieldComponent = Color(0xFF212124);
  static const Color darkBgFieldComponentHover = Color(0xFF27272A);
  static const Color darkBgDisabled = Color(0xFF27272A);
  static const Color darkBgHover = Color(0xFF27272A);
  static const Color darkBgInteractive = Color(0xFF60A5FA);
  static const Color darkBgHighlight = Color(0xFF172554);
  static const Color darkBgHighlightHover = Color(0xFF1E3A8A);
  static const Color darkBgOverlay = Color(0xFF18181B);
  static const double darkBgOverlayAlpha = 0.72;
  static const Color darkBgSwitchOff = Color(0xFF3F3F46);
  static const Color darkBgSwitchOffHover = Color(0xFF52525B);

  static const Color darkFgBase = Color(0xFFF4F4F5);
  static const Color darkFgSubtle = Color(0xFFA1A1AA);
  static const Color darkFgMuted = Color(0xFF71717A);
  static const Color darkFgDisabled = Color(0xFF52525B);
  static const Color darkFgOnColor = Color(0xFFFFFFFF);
  static const Color darkFgOnInverted = Color(0xFF18181B);
  static const Color darkFgInteractive = Color(0xFF60A5FA);
  static const Color darkFgInteractiveHover = Color(0xFF93C5FD);
  static const Color darkFgError = Color(0xFFFB7185);

  static const Color darkBorderBase = Color(0xFF2A2A30);
  static const Color darkBorderStrong = Color(0xFF46464E);
  static const Color darkBorderInteractive = Color(0xFF60A5FA);
  static const Color darkBorderError = Color(0xFFFB7185);
  static const Color darkBorderDanger = Color(0xFFBE123C);
  static const Color darkBorderMenuTop = Color(0xFF212124);
  static const Color darkBorderMenuBot = Color(0xFF3F3F46);

  // ---------------------------------------------------------------------------
  // Tag Colors (Neutral / Blue / Green / Orange / Red / Purple / Amber)
  // ---------------------------------------------------------------------------
  static const Color tagNeutralBg = Color(0xFFF4F4F5);
  static const Color tagNeutralBgHover = Color(0xFFE4E4E7);
  static const Color tagNeutralText = Color(0xFF52525B);
  static const Color tagNeutralIcon = Color(0xFFA1A1AA);
  static const Color tagNeutralBorder = Color(0xFFE4E4E7);

  static const Color tagBlueBg = Color(0xFFDBEAFE);
  static const Color tagBlueBgHover = Color(0xFFBFDBFE);
  static const Color tagBlueText = Color(0xFF1E40AF);
  static const Color tagBlueIcon = Color(0xFF60A5FA);
  static const Color tagBlueBorder = Color(0xFFBFDBFE);

  static const Color tagGreenBg = Color(0xFFD1FAE5);
  static const Color tagGreenBgHover = Color(0xFFA7F3D0);
  static const Color tagGreenText = Color(0xFF065F46);
  static const Color tagGreenIcon = Color(0xFF10B981);
  static const Color tagGreenBorder = Color(0xFFA7F3D0);

  static const Color tagOrangeBg = Color(0xFFFFEDD5);
  static const Color tagOrangeBgHover = Color(0xFFFED7AA);
  static const Color tagOrangeText = Color(0xFF9A3412);
  static const Color tagOrangeIcon = Color(0xFFF97316);
  static const Color tagOrangeBorder = Color(0xFFFED7AA);

  static const Color tagRedBg = Color(0xFFFFE4E6);
  static const Color tagRedBgHover = Color(0xFFFECDD3);
  static const Color tagRedText = Color(0xFF9F1239);
  static const Color tagRedIcon = Color(0xFFF43F5E);
  static const Color tagRedBorder = Color(0xFFFECDD3);

  static const Color tagPurpleBg = Color(0xFFEDE9FE);
  static const Color tagPurpleBgHover = Color(0xFFDDD6FE);
  static const Color tagPurpleText = Color(0xFF5B21B6);
  static const Color tagPurpleIcon = Color(0xFFA78BFA);
  static const Color tagPurpleBorder = Color(0xFFDDD6FE);

  static const Color tagAmberBg = Color(0xFFFEF9C3);
  static const Color tagAmberBgHover = Color(0xFFFDE68A);
  static const Color tagAmberText = Color(0xFF78350F);
  static const Color tagAmberIcon = Color(0xFFCA8A04);
  static const Color tagAmberBorder = Color(0xFFFCD34D);

  // ---------------------------------------------------------------------------
  // HotelOps Specific Colors
  // ---------------------------------------------------------------------------
  static const Color kpiNeutralTint = Color(0xFFF6F4FB);
  static const Color kpiOverdueTint = Color(0xFFFBE7EB);
  static const Color kpiOverdueText = Color(0xFFD7263D);

  static const Color ticketStripeUniversal = Color(0xFF7B5CFF);
  static const Color ticketStripeInProgress = Color(0xFF7B5CFF);
  static const Color ticketStripeDone = Color(0xFF21B26A);
  static const Color ticketStripeOverdue = Color(0xFFD7263D);

  static const Color chipUniversalBg = Color(0xFFEFE8FF);
  static const Color chipUniversalFg = Color(0xFF5C3BE5);
  static const Color chipCatalogBg = Color(0xFFE6F4FF);
  static const Color chipCatalogFg = Color(0xFF1A6FD9);
  static const Color chipManualBg = Color(0xFFFFE8E1);
  static const Color chipManualFg = Color(0xFFC74A1D);

  static const Color statusInProgress = Color(0xFF7B5CFF);
  static const Color statusDone = Color(0xFF21B26A);
  static const Color statusOverdue = Color(0xFFD7263D);
  static const Color statusUnassigned = Color(0xFF8B8FA3);

  static const Color noteCalloutBg = Color(0xFFFFF7CC);
  static const Color noteCalloutFg = Color(0xFF6B5A00);
  static const Color noteCalloutAccent = Color(0xFFE7C800);

  static const Color opsSurface = Color(0xFFFFFFFF);
  static const Color opsSurfaceSubtle = Color(0xFFF7F7FB);
  static const Color opsBorder = Color(0xFFEDEDF3);
  static const Color opsDividerSubtle = Color(0xFFF0F0F4);

  static const Color subTabBg = Color(0xFFF1F1F6);
  static const Color subTabActiveBg = Color(0xFF111322);
  static const Color subTabActiveFg = Color(0xFFFFFFFF);
  static const Color subTabInactiveFg = Color(0xFF6B7180);

  // ---------------------------------------------------------------------------
  // Login Screen Colors
  // ---------------------------------------------------------------------------
  static const Color loginBgTop = Color(0xFF2A1B4A);
  static const Color loginBgBottom = Color(0xFF0E0A1B);
  static const Color loginCardBg = Color(0x12FFFFFF);
  static const Color loginCardBorder = Color(0x14FFFFFF);
  static const Color loginDivider = Color(0x1AFFFFFF);
  static const Color loginLogoBg = Color(0x14FFFFFF);
  static const Color loginLogoBorder = Color(0x33FFFFFF);
  static const Color loginLogoIcon = Color(0xFFFFFFFF);
  static const Color loginTitle = Color(0xFFFFFFFF);
  static const Color loginSubtitle = Color(0xFF9A93AE);
  static const Color loginFieldLabel = Color(0xFFFFFFFF);
  static const Color loginRequiredAsterisk = Color(0xFFE91E63);
  static const Color loginTabTrack = Color(0x0AFFFFFF);
  static const Color loginTabBorder = Color(0x1FFFFFFF);
  static const Color loginTabSelectedBg = Color(0xFF1A1230);
  static const Color loginTabSelectedFg = Color(0xFFFFFFFF);
  static const Color loginTabUnselectedFg = Color(0xFF7A7390);
  static const Color loginInputBg = Color(0x0AFFFFFF);
  static const Color loginInputBorder = Color(0x1FFFFFFF);
  static const Color loginInputIcon = Color(0xFF7A7390);
  static const Color loginInputText = Color(0xFFFFFFFF);
  static const Color loginInputHint = Color(0xFF6B6582);
  static const Color loginInputDivider = Color(0x1FFFFFFF);
  static const Color loginButtonDisabledBg = Color(0xFF2A2440);
  static const Color loginButtonDisabledFg = Color(0xFF8A8499);
  static const Color loginFooterText = Color(0xFF8A8499);

  // ---------------------------------------------------------------------------
  // Theme Data Builders
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);
  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colors = isDark ? _DarkColors() : _LightColors();
    // Full AppColors token set — required by context.themeColors and
    // context.appColors across the entire widget tree.
    final appColors = isDark ? AppColors.dark : AppColors.light;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
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
        inverseSurface: const Color(0xFF27272A),
        onInverseSurface: const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: colors.bgSubtle,
      canvasColor: colors.bgBase,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        foregroundColor: colors.fgBase,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.fgBase),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF18181B),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderBase),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.bgBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.fgInteractive,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[colors, appColors],
    );
  }
}

// ---------------------------------------------------------------------------
// Color Classes for Theme Extension
// ---------------------------------------------------------------------------

abstract class _ThemeColors extends ThemeExtension<_ThemeColors> {
  final Color bgBase;
  final Color bgSubtle;
  final Color bgComponent;
  final Color bgField;
  final Color bgInteractive;
  final Color bgHighlight;
  final Color bgOverlay;
  final Color fgBase;
  final Color fgSubtle;
  final Color fgMuted;
  final Color fgDisabled;
  final Color fgOnColor;
  final Color fgInteractive;
  final Color fgError;
  final Color borderBase;
  final Color borderStrong;
  final Color borderInteractive;
  final Color borderError;
  final Color tagPurpleIcon;

  const _ThemeColors({
    required this.bgBase,
    required this.bgSubtle,
    required this.bgComponent,
    required this.bgField,
    required this.bgInteractive,
    required this.bgHighlight,
    required this.bgOverlay,
    required this.fgBase,
    required this.fgSubtle,
    required this.fgMuted,
    required this.fgDisabled,
    required this.fgOnColor,
    required this.fgInteractive,
    required this.fgError,
    required this.borderBase,
    required this.borderStrong,
    required this.borderInteractive,
    required this.borderError,
    required this.tagPurpleIcon,
  });
}

class _LightColors extends _ThemeColors {
  const _LightColors() : super(
    bgBase: UnifiedThemeManager.lightBgBase,
    bgSubtle: UnifiedThemeManager.lightBgSubtle,
    bgComponent: UnifiedThemeManager.lightBgComponent,
    bgField: UnifiedThemeManager.lightBgField,
    bgInteractive: UnifiedThemeManager.lightBgInteractive,
    bgHighlight: UnifiedThemeManager.lightBgHighlight,
    bgOverlay: UnifiedThemeManager.lightBgOverlay,
    fgBase: UnifiedThemeManager.lightFgBase,
    fgSubtle: UnifiedThemeManager.lightFgSubtle,
    fgMuted: UnifiedThemeManager.lightFgMuted,
    fgDisabled: UnifiedThemeManager.lightFgDisabled,
    fgOnColor: UnifiedThemeManager.lightFgOnColor,
    fgInteractive: UnifiedThemeManager.lightFgInteractive,
    fgError: UnifiedThemeManager.lightFgError,
    borderBase: UnifiedThemeManager.lightBorderBase,
    borderStrong: UnifiedThemeManager.lightBorderStrong,
    borderInteractive: UnifiedThemeManager.lightBorderInteractive,
    borderError: UnifiedThemeManager.lightBorderError,
    tagPurpleIcon: UnifiedThemeManager.opsPurple,
  );

  @override
  _ThemeColors copyWith({
    Color? bgBase,
    Color? bgSubtle,
    Color? bgComponent,
    Color? bgField,
    Color? bgInteractive,
    Color? bgHighlight,
    Color? bgOverlay,
    Color? fgBase,
    Color? fgSubtle,
    Color? fgMuted,
    Color? fgDisabled,
    Color? fgOnColor,
    Color? fgInteractive,
    Color? fgError,
    Color? borderBase,
    Color? borderStrong,
    Color? borderInteractive,
    Color? borderError,
    Color? tagPurpleIcon,
  }) {
    return _LightColors();
  }

  @override
  _ThemeColors lerp(ThemeExtension<_ThemeColors>? other, double t) {
    if (other is! _ThemeColors) return this;
    return this;
  }
}

class _DarkColors extends _ThemeColors {
  const _DarkColors() : super(
    bgBase: UnifiedThemeManager.darkBgBase,
    bgSubtle: UnifiedThemeManager.darkBgSubtle,
    bgComponent: UnifiedThemeManager.darkBgComponent,
    bgField: UnifiedThemeManager.darkBgField,
    bgInteractive: UnifiedThemeManager.darkBgInteractive,
    bgHighlight: UnifiedThemeManager.darkBgHighlight,
    bgOverlay: UnifiedThemeManager.darkBgOverlay,
    fgBase: UnifiedThemeManager.darkFgBase,
    fgSubtle: UnifiedThemeManager.darkFgSubtle,
    fgMuted: UnifiedThemeManager.darkFgMuted,
    fgDisabled: UnifiedThemeManager.darkFgDisabled,
    fgOnColor: UnifiedThemeManager.darkFgOnColor,
    fgInteractive: UnifiedThemeManager.darkFgInteractive,
    fgError: UnifiedThemeManager.darkFgError,
    borderBase: UnifiedThemeManager.darkBorderBase,
    borderStrong: UnifiedThemeManager.darkBorderStrong,
    borderInteractive: UnifiedThemeManager.darkBorderInteractive,
    borderError: UnifiedThemeManager.darkBorderError,
    tagPurpleIcon: UnifiedThemeManager.opsPurple,
  );

  @override
  _ThemeColors copyWith({
    Color? bgBase,
    Color? bgSubtle,
    Color? bgComponent,
    Color? bgField,
    Color? bgInteractive,
    Color? bgHighlight,
    Color? bgOverlay,
    Color? fgBase,
    Color? fgSubtle,
    Color? fgMuted,
    Color? fgDisabled,
    Color? fgOnColor,
    Color? fgInteractive,
    Color? fgError,
    Color? borderBase,
    Color? borderStrong,
    Color? borderInteractive,
    Color? borderError,
    Color? tagPurpleIcon,
  }) {
    return _DarkColors();
  }

  @override
  _ThemeColors lerp(ThemeExtension<_ThemeColors>? other, double t) {
    if (other is! _ThemeColors) return this;
    return this;
  }
}

/// Extension for easy access to theme colors.
/// Returns the full [AppColors] token set so all tag/contrast tokens are
/// available via `context.themeColors.*` — identical to `context.appColors`.
extension UnifiedThemeContext on BuildContext {
  AppColors get themeColors {
    final ext = Theme.of(this).extension<AppColors>();
    assert(
      ext != null,
      'AppColors not installed on ThemeData — make sure ThemeManager built '
      'the active theme.',
    );
    return ext ?? AppColors.light;
  }
}
