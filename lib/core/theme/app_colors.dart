import 'package:flutter/material.dart';

/// HotelOps / Medusa colour tokens, theme-aware.
///
/// Values are a 1:1 port of `frontend/src/index.css` (the React design
/// system). Every token has a Light and a Dark variant; the variant in use
/// is decided by `Theme.of(context).extension<AppColors>()` which Flutter
/// resolves automatically based on the active `ThemeMode`.
///
/// **Why a `ThemeExtension`?**
/// Flutter's `Theme.of(context)` already tracks light/dark/system. Adding
/// our tokens as a `ThemeExtension` means widgets simply read
/// `context.themeColors.bgBase` and the right value is returned for the
/// current theme — no explicit `if (isDark)` checks anywhere in widgets.
/// Per `docs/04_BASE_LAYER_RULES.md` (no hardcoded colours, no duplicate
/// styles) and `docs/07_STATE_AND_LIFECYCLE_RULES.md` (theme is persistent
/// state, owned by the theme controller).
///
/// **Why both this and the legacy `ColorPalette`?**
/// Existing screens still reference `ColorPalette.opsPurple` / `opsSurface`
/// directly. Migrating every widget to `AppColors` is a per-feature
/// follow-up — until then both coexist. New work MUST use `AppColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // ---------------------------------------------------------------------------
  // Background surfaces
  // ---------------------------------------------------------------------------
  final Color bgBase;
  final Color bgBaseHover;
  final Color bgBasePressed;
  final Color bgSubtle;
  final Color bgSubtleHover;
  final Color bgSubtlePressed;
  final Color bgComponent;
  final Color bgComponentHover;
  final Color bgComponentPressed;
  final Color bgField;
  final Color bgFieldHover;
  final Color bgFieldComponent;
  final Color bgFieldComponentHover;
  final Color bgDisabled;
  final Color bgHover;
  final Color bgInteractive;
  final Color bgHighlight;
  final Color bgHighlightHover;
  final Color bgOverlay;
  final double bgOverlayAlpha;
  final Color bgSwitchOff;
  final Color bgSwitchOffHover;

  // ---------------------------------------------------------------------------
  // Foreground (text + icon)
  // ---------------------------------------------------------------------------
  final Color fgBase;
  final Color fgSubtle;
  final Color fgMuted;
  final Color fgDisabled;
  final Color fgOnColor;
  final Color fgOnInverted;
  final Color fgInteractive;
  final Color fgInteractiveHover;
  final Color fgError;

  // ---------------------------------------------------------------------------
  // Borders
  // ---------------------------------------------------------------------------
  final Color borderBase;
  final Color borderStrong;
  final Color borderInteractive;
  final Color borderError;
  final Color borderDanger;
  final Color borderMenuTop;
  final Color borderMenuBot;

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------
  final Color buttonNeutral;
  final Color buttonNeutralHover;
  final Color buttonNeutralPressed;
  final Color buttonInverted;
  final Color buttonInvertedHover;
  final Color buttonInvertedPressed;
  final Color buttonDanger;
  final Color buttonDangerHover;
  final Color buttonDangerPressed;
  final Color buttonTransparentHover;
  final Color buttonTransparentPressed;

  // ---------------------------------------------------------------------------
  // Tag palettes (neutral / blue / green / orange / red / purple / amber)
  // ---------------------------------------------------------------------------
  final Color tagNeutralBg;
  final Color tagNeutralBgHover;
  final Color tagNeutralText;
  final Color tagNeutralIcon;
  final Color tagNeutralBorder;
  final Color tagBlueBg;
  final Color tagBlueBgHover;
  final Color tagBlueText;
  final Color tagBlueIcon;
  final Color tagBlueBorder;
  final Color tagGreenBg;
  final Color tagGreenBgHover;
  final Color tagGreenText;
  final Color tagGreenIcon;
  final Color tagGreenBorder;
  final Color tagOrangeBg;
  final Color tagOrangeBgHover;
  final Color tagOrangeText;
  final Color tagOrangeIcon;
  final Color tagOrangeBorder;
  final Color tagRedBg;
  final Color tagRedBgHover;
  final Color tagRedText;
  final Color tagRedIcon;
  final Color tagRedBorder;
  final Color tagPurpleBg;
  final Color tagPurpleBgHover;
  final Color tagPurpleText;
  final Color tagPurpleIcon;
  final Color tagPurpleBorder;
  final Color tagAmberBg;
  final Color tagAmberBgHover;
  final Color tagAmberText;
  final Color tagAmberIcon;
  final Color tagAmberBorder;

  // ---------------------------------------------------------------------------
  // High-contrast surfaces (used for dark inserts inside light themes etc.)
  // ---------------------------------------------------------------------------
  final Color contrastBgBase;
  final Color contrastBgBaseHover;
  final Color contrastBgBasePressed;
  final Color contrastBgSubtle;
  final Color contrastFgPrimary;
  final double contrastFgPrimaryAlpha;
  final Color contrastFgSecondary;
  final double contrastFgSecondaryAlpha;
  final Color contrastBorderBase;
  final double contrastBorderBaseAlpha;

  const AppColors({
    required this.bgBase,
    required this.bgBaseHover,
    required this.bgBasePressed,
    required this.bgSubtle,
    required this.bgSubtleHover,
    required this.bgSubtlePressed,
    required this.bgComponent,
    required this.bgComponentHover,
    required this.bgComponentPressed,
    required this.bgField,
    required this.bgFieldHover,
    required this.bgFieldComponent,
    required this.bgFieldComponentHover,
    required this.bgDisabled,
    required this.bgHover,
    required this.bgInteractive,
    required this.bgHighlight,
    required this.bgHighlightHover,
    required this.bgOverlay,
    required this.bgOverlayAlpha,
    required this.bgSwitchOff,
    required this.bgSwitchOffHover,
    required this.fgBase,
    required this.fgSubtle,
    required this.fgMuted,
    required this.fgDisabled,
    required this.fgOnColor,
    required this.fgOnInverted,
    required this.fgInteractive,
    required this.fgInteractiveHover,
    required this.fgError,
    required this.borderBase,
    required this.borderStrong,
    required this.borderInteractive,
    required this.borderError,
    required this.borderDanger,
    required this.borderMenuTop,
    required this.borderMenuBot,
    required this.buttonNeutral,
    required this.buttonNeutralHover,
    required this.buttonNeutralPressed,
    required this.buttonInverted,
    required this.buttonInvertedHover,
    required this.buttonInvertedPressed,
    required this.buttonDanger,
    required this.buttonDangerHover,
    required this.buttonDangerPressed,
    required this.buttonTransparentHover,
    required this.buttonTransparentPressed,
    required this.tagNeutralBg,
    required this.tagNeutralBgHover,
    required this.tagNeutralText,
    required this.tagNeutralIcon,
    required this.tagNeutralBorder,
    required this.tagBlueBg,
    required this.tagBlueBgHover,
    required this.tagBlueText,
    required this.tagBlueIcon,
    required this.tagBlueBorder,
    required this.tagGreenBg,
    required this.tagGreenBgHover,
    required this.tagGreenText,
    required this.tagGreenIcon,
    required this.tagGreenBorder,
    required this.tagOrangeBg,
    required this.tagOrangeBgHover,
    required this.tagOrangeText,
    required this.tagOrangeIcon,
    required this.tagOrangeBorder,
    required this.tagRedBg,
    required this.tagRedBgHover,
    required this.tagRedText,
    required this.tagRedIcon,
    required this.tagRedBorder,
    required this.tagPurpleBg,
    required this.tagPurpleBgHover,
    required this.tagPurpleText,
    required this.tagPurpleIcon,
    required this.tagPurpleBorder,
    required this.tagAmberBg,
    required this.tagAmberBgHover,
    required this.tagAmberText,
    required this.tagAmberIcon,
    required this.tagAmberBorder,
    required this.contrastBgBase,
    required this.contrastBgBaseHover,
    required this.contrastBgBasePressed,
    required this.contrastBgSubtle,
    required this.contrastFgPrimary,
    required this.contrastFgPrimaryAlpha,
    required this.contrastFgSecondary,
    required this.contrastFgSecondaryAlpha,
    required this.contrastBorderBase,
    required this.contrastBorderBaseAlpha,
  });

  // ---------------------------------------------------------------------------
  // Light variant — `:root` block in the React index.css
  // ---------------------------------------------------------------------------
  static const AppColors light = AppColors(
    bgBase: Color(0xFFFFFFFF),
    bgBaseHover: Color(0xFFF4F4F5),
    bgBasePressed: Color(0xFFE4E4E7),
    bgSubtle: Color(0xFFFAFAFA),
    bgSubtleHover: Color(0xFFF4F4F5),
    bgSubtlePressed: Color(0xFFE4E4E7),
    bgComponent: Color(0xFFFAFAFA),
    bgComponentHover: Color(0xFFF4F4F5),
    bgComponentPressed: Color(0xFFE4E4E7),
    bgField: Color(0xFFFAFAFA),
    bgFieldHover: Color(0xFFF4F4F5),
    bgFieldComponent: Color(0xFFFFFFFF),
    bgFieldComponentHover: Color(0xFFFAFAFA),
    bgDisabled: Color(0xFFF4F4F5),
    bgHover: Color(0xFFF4F4F5),
    bgInteractive: Color(0xFF3B82F6),
    bgHighlight: Color(0xFFEFF6FF),
    bgHighlightHover: Color(0xFFDBEAFE),
    bgOverlay: Color(0xFF18181B),
    bgOverlayAlpha: 0.4,
    bgSwitchOff: Color(0xFFE4E4E7),
    bgSwitchOffHover: Color(0xFFD4D4D8),
    fgBase: Color(0xFF18181B),
    fgSubtle: Color(0xFF52525B),
    fgMuted: Color(0xFF71717A),
    fgDisabled: Color(0xFFA1A1AA),
    fgOnColor: Color(0xFFFFFFFF),
    fgOnInverted: Color(0xFFFFFFFF),
    fgInteractive: Color(0xFF3B82F6),
    fgInteractiveHover: Color(0xFF2563EB),
    fgError: Color(0xFFE11D48),
    borderBase: Color(0xFFE4E4E7),
    borderStrong: Color(0xFFD4D4D8),
    borderInteractive: Color(0xFF3B82F6),
    borderError: Color(0xFFE11D48),
    borderDanger: Color(0xFFBE123C),
    borderMenuTop: Color(0xFFE4E4E7),
    borderMenuBot: Color(0xFFFFFFFF),
    buttonNeutral: Color(0xFFFFFFFF),
    buttonNeutralHover: Color(0xFFF4F4F5),
    buttonNeutralPressed: Color(0xFFE4E4E7),
    buttonInverted: Color(0xFF27272A),
    buttonInvertedHover: Color(0xFF3F3F46),
    buttonInvertedPressed: Color(0xFF52525B),
    buttonDanger: Color(0xFFE11D48),
    buttonDangerHover: Color(0xFFBE123C),
    buttonDangerPressed: Color(0xFF9F1239),
    buttonTransparentHover: Color(0xFFF4F4F5),
    buttonTransparentPressed: Color(0xFFE4E4E7),
    tagNeutralBg: Color(0xFFF4F4F5),
    tagNeutralBgHover: Color(0xFFE4E4E7),
    tagNeutralText: Color(0xFF52525B),
    tagNeutralIcon: Color(0xFFA1A1AA),
    tagNeutralBorder: Color(0xFFE4E4E7),
    tagBlueBg: Color(0xFFDBEAFE),
    tagBlueBgHover: Color(0xFFBFDBFE),
    tagBlueText: Color(0xFF1E40AF),
    tagBlueIcon: Color(0xFF60A5FA),
    tagBlueBorder: Color(0xFFBFDBFE),
    tagGreenBg: Color(0xFFD1FAE5),
    tagGreenBgHover: Color(0xFFA7F3D0),
    tagGreenText: Color(0xFF065F46),
    tagGreenIcon: Color(0xFF10B981),
    tagGreenBorder: Color(0xFFA7F3D0),
    tagOrangeBg: Color(0xFFFFEDD5),
    tagOrangeBgHover: Color(0xFFFED7AA),
    tagOrangeText: Color(0xFF9A3412),
    tagOrangeIcon: Color(0xFFF97316),
    tagOrangeBorder: Color(0xFFFED7AA),
    tagRedBg: Color(0xFFFFE4E6),
    tagRedBgHover: Color(0xFFFECDD3),
    tagRedText: Color(0xFF9F1239),
    tagRedIcon: Color(0xFFF43F5E),
    tagRedBorder: Color(0xFFFECDD3),
    tagPurpleBg: Color(0xFFEDE9FE),
    tagPurpleBgHover: Color(0xFFDDD6FE),
    tagPurpleText: Color(0xFF5B21B6),
    tagPurpleIcon: Color(0xFFA78BFA),
    tagPurpleBorder: Color(0xFFDDD6FE),
    tagAmberBg: Color(0xFFFEF9C3),
    tagAmberBgHover: Color(0xFFFDE68A),
    tagAmberText: Color(0xFF78350F),
    tagAmberIcon: Color(0xFFCA8A04),
    tagAmberBorder: Color(0xFFFCD34D),
    contrastBgBase: Color(0xFF18181B),
    contrastBgBaseHover: Color(0xFF27272A),
    contrastBgBasePressed: Color(0xFF3F3F46),
    contrastBgSubtle: Color(0xFF27272A),
    contrastFgPrimary: Color(0xFFFFFFFF),
    contrastFgPrimaryAlpha: 0.88,
    contrastFgSecondary: Color(0xFFFFFFFF),
    contrastFgSecondaryAlpha: 0.56,
    contrastBorderBase: Color(0xFFFFFFFF),
    contrastBorderBaseAlpha: 0.15,
  );

  // ---------------------------------------------------------------------------
  // Dark variant — `.dark` block in the React index.css. The page bg is
  // pushed to near-black; cards sit on a slightly elevated charcoal so the
  // surface separation is felt without explicit borders.
  // ---------------------------------------------------------------------------
  static const AppColors dark = AppColors(
    bgBase: Color(0xFF1A1A1E),
    bgBaseHover: Color(0xFF222226),
    bgBasePressed: Color(0xFF2C2C32),
    bgSubtle: Color(0xFF0E0E11),
    bgSubtleHover: Color(0xFF16161A),
    bgSubtlePressed: Color(0xFF1E1E22),
    bgComponent: Color(0xFF222226),
    bgComponentHover: Color(0xFF3F3F46),
    bgComponentPressed: Color(0xFF52525B),
    bgField: Color(0xFF37373C),
    bgFieldHover: Color(0xFF424248),
    bgFieldComponent: Color(0xFF212124),
    bgFieldComponentHover: Color(0xFF27272A),
    bgDisabled: Color(0xFF27272A),
    bgHover: Color(0xFF27272A),
    bgInteractive: Color(0xFF60A5FA),
    bgHighlight: Color(0xFF172554),
    bgHighlightHover: Color(0xFF1E3A8A),
    bgOverlay: Color(0xFF18181B),
    bgOverlayAlpha: 0.72,
    bgSwitchOff: Color(0xFF3F3F46),
    bgSwitchOffHover: Color(0xFF52525B),
    fgBase: Color(0xFFF4F4F5),
    fgSubtle: Color(0xFFA1A1AA),
    fgMuted: Color(0xFF71717A),
    fgDisabled: Color(0xFF52525B),
    fgOnColor: Color(0xFFFFFFFF),
    fgOnInverted: Color(0xFF18181B),
    fgInteractive: Color(0xFF60A5FA),
    fgInteractiveHover: Color(0xFF93C5FD),
    fgError: Color(0xFFFB7185),
    borderBase: Color(0xFF2A2A30),
    borderStrong: Color(0xFF46464E),
    borderInteractive: Color(0xFF60A5FA),
    borderError: Color(0xFFFB7185),
    borderDanger: Color(0xFFBE123C),
    borderMenuTop: Color(0xFF212124),
    borderMenuBot: Color(0xFF3F3F46),
    buttonNeutral: Color(0xFF27272A),
    buttonNeutralHover: Color(0xFF3F3F46),
    buttonNeutralPressed: Color(0xFF52525B),
    buttonInverted: Color(0xFF52525B),
    buttonInvertedHover: Color(0xFF71717A),
    buttonInvertedPressed: Color(0xFFA1A1AA),
    buttonDanger: Color(0xFF9F1239),
    buttonDangerHover: Color(0xFFBE123C),
    buttonDangerPressed: Color(0xFFE11D48),
    buttonTransparentHover: Color(0xFF3F3F46),
    buttonTransparentPressed: Color(0xFF52525B),
    tagNeutralBg: Color(0xFF3F3F46),
    tagNeutralBgHover: Color(0xFF52525B),
    tagNeutralText: Color(0xFFD4D4D8),
    tagNeutralIcon: Color(0xFF71717A),
    tagNeutralBorder: Color(0xFF52525B),
    tagBlueBg: Color(0xFF172554),
    tagBlueBgHover: Color(0xFF1E3A8A),
    tagBlueText: Color(0xFF93C5FD),
    tagBlueIcon: Color(0xFF60A5FA),
    tagBlueBorder: Color(0xFF1E3A8A),
    tagGreenBg: Color(0xFF022C22),
    tagGreenBgHover: Color(0xFF064E3B),
    tagGreenText: Color(0xFF34D399),
    tagGreenIcon: Color(0xFF10B981),
    tagGreenBorder: Color(0xFF064E3B),
    tagOrangeBg: Color(0xFF431407),
    tagOrangeBgHover: Color(0xFF7C2D12),
    tagOrangeText: Color(0xFFFDBA74),
    tagOrangeIcon: Color(0xFFFB923C),
    tagOrangeBorder: Color(0xFF7C2D12),
    tagRedBg: Color(0xFF4C0519),
    tagRedBgHover: Color(0xFF881337),
    tagRedText: Color(0xFFFDA4AF),
    tagRedIcon: Color(0xFFFB7185),
    tagRedBorder: Color(0xFF881337),
    tagPurpleBg: Color(0xFF2E1065),
    tagPurpleBgHover: Color(0xFF5B21B6),
    tagPurpleText: Color(0xFFC4B5FD),
    tagPurpleIcon: Color(0xFFA78BFA),
    tagPurpleBorder: Color(0xFF5B21B6),
    tagAmberBg: Color(0xFF2B1D04),
    tagAmberBgHover: Color(0xFF78350F),
    tagAmberText: Color(0xFFFCD34D),
    tagAmberIcon: Color(0xFFFCD34D),
    tagAmberBorder: Color(0xFFB45309),
    contrastBgBase: Color(0xFF27272A),
    contrastBgBaseHover: Color(0xFF3F3F46),
    contrastBgBasePressed: Color(0xFF52525B),
    contrastBgSubtle: Color(0xFF18181B),
    contrastFgPrimary: Color(0xFFFFFFFF),
    contrastFgPrimaryAlpha: 0.88,
    contrastFgSecondary: Color(0xFFFFFFFF),
    contrastFgSecondaryAlpha: 0.56,
    contrastBorderBase: Color(0xFFFFFFFF),
    contrastBorderBaseAlpha: 0.15,
  );

  @override
  AppColors copyWith({
    Color? bgBase,
    Color? bgSubtle,
    Color? bgComponent,
    Color? fgBase,
    Color? fgSubtle,
    Color? fgMuted,
    Color? borderBase,
    Color? borderStrong,
  }) {
    // copyWith intentionally exposes only the most-overridden tokens; tests
    // and theming experiments rarely need more, and adding all 90 fields
    // here would just be noise. Add more as the need actually arises.
    return AppColors(
      bgBase: bgBase ?? this.bgBase,
      bgBaseHover: bgBaseHover,
      bgBasePressed: bgBasePressed,
      bgSubtle: bgSubtle ?? this.bgSubtle,
      bgSubtleHover: bgSubtleHover,
      bgSubtlePressed: bgSubtlePressed,
      bgComponent: bgComponent ?? this.bgComponent,
      bgComponentHover: bgComponentHover,
      bgComponentPressed: bgComponentPressed,
      bgField: bgField,
      bgFieldHover: bgFieldHover,
      bgFieldComponent: bgFieldComponent,
      bgFieldComponentHover: bgFieldComponentHover,
      bgDisabled: bgDisabled,
      bgHover: bgHover,
      bgInteractive: bgInteractive,
      bgHighlight: bgHighlight,
      bgHighlightHover: bgHighlightHover,
      bgOverlay: bgOverlay,
      bgOverlayAlpha: bgOverlayAlpha,
      bgSwitchOff: bgSwitchOff,
      bgSwitchOffHover: bgSwitchOffHover,
      fgBase: fgBase ?? this.fgBase,
      fgSubtle: fgSubtle ?? this.fgSubtle,
      fgMuted: fgMuted ?? this.fgMuted,
      fgDisabled: fgDisabled,
      fgOnColor: fgOnColor,
      fgOnInverted: fgOnInverted,
      fgInteractive: fgInteractive,
      fgInteractiveHover: fgInteractiveHover,
      fgError: fgError,
      borderBase: borderBase ?? this.borderBase,
      borderStrong: borderStrong ?? this.borderStrong,
      borderInteractive: borderInteractive,
      borderError: borderError,
      borderDanger: borderDanger,
      borderMenuTop: borderMenuTop,
      borderMenuBot: borderMenuBot,
      buttonNeutral: buttonNeutral,
      buttonNeutralHover: buttonNeutralHover,
      buttonNeutralPressed: buttonNeutralPressed,
      buttonInverted: buttonInverted,
      buttonInvertedHover: buttonInvertedHover,
      buttonInvertedPressed: buttonInvertedPressed,
      buttonDanger: buttonDanger,
      buttonDangerHover: buttonDangerHover,
      buttonDangerPressed: buttonDangerPressed,
      buttonTransparentHover: buttonTransparentHover,
      buttonTransparentPressed: buttonTransparentPressed,
      tagNeutralBg: tagNeutralBg,
      tagNeutralBgHover: tagNeutralBgHover,
      tagNeutralText: tagNeutralText,
      tagNeutralIcon: tagNeutralIcon,
      tagNeutralBorder: tagNeutralBorder,
      tagBlueBg: tagBlueBg,
      tagBlueBgHover: tagBlueBgHover,
      tagBlueText: tagBlueText,
      tagBlueIcon: tagBlueIcon,
      tagBlueBorder: tagBlueBorder,
      tagGreenBg: tagGreenBg,
      tagGreenBgHover: tagGreenBgHover,
      tagGreenText: tagGreenText,
      tagGreenIcon: tagGreenIcon,
      tagGreenBorder: tagGreenBorder,
      tagOrangeBg: tagOrangeBg,
      tagOrangeBgHover: tagOrangeBgHover,
      tagOrangeText: tagOrangeText,
      tagOrangeIcon: tagOrangeIcon,
      tagOrangeBorder: tagOrangeBorder,
      tagRedBg: tagRedBg,
      tagRedBgHover: tagRedBgHover,
      tagRedText: tagRedText,
      tagRedIcon: tagRedIcon,
      tagRedBorder: tagRedBorder,
      tagPurpleBg: tagPurpleBg,
      tagPurpleBgHover: tagPurpleBgHover,
      tagPurpleText: tagPurpleText,
      tagPurpleIcon: tagPurpleIcon,
      tagPurpleBorder: tagPurpleBorder,
      tagAmberBg: tagAmberBg,
      tagAmberBgHover: tagAmberBgHover,
      tagAmberText: tagAmberText,
      tagAmberIcon: tagAmberIcon,
      tagAmberBorder: tagAmberBorder,
      contrastBgBase: contrastBgBase,
      contrastBgBaseHover: contrastBgBaseHover,
      contrastBgBasePressed: contrastBgBasePressed,
      contrastBgSubtle: contrastBgSubtle,
      contrastFgPrimary: contrastFgPrimary,
      contrastFgPrimaryAlpha: contrastFgPrimaryAlpha,
      contrastFgSecondary: contrastFgSecondary,
      contrastFgSecondaryAlpha: contrastFgSecondaryAlpha,
      contrastBorderBase: contrastBorderBase,
      contrastBorderBaseAlpha: contrastBorderBaseAlpha,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    double d(double a, double b) => a + (b - a) * t;
    return AppColors(
      bgBase: l(bgBase, other.bgBase),
      bgBaseHover: l(bgBaseHover, other.bgBaseHover),
      bgBasePressed: l(bgBasePressed, other.bgBasePressed),
      bgSubtle: l(bgSubtle, other.bgSubtle),
      bgSubtleHover: l(bgSubtleHover, other.bgSubtleHover),
      bgSubtlePressed: l(bgSubtlePressed, other.bgSubtlePressed),
      bgComponent: l(bgComponent, other.bgComponent),
      bgComponentHover: l(bgComponentHover, other.bgComponentHover),
      bgComponentPressed: l(bgComponentPressed, other.bgComponentPressed),
      bgField: l(bgField, other.bgField),
      bgFieldHover: l(bgFieldHover, other.bgFieldHover),
      bgFieldComponent: l(bgFieldComponent, other.bgFieldComponent),
      bgFieldComponentHover: l(
        bgFieldComponentHover,
        other.bgFieldComponentHover,
      ),
      bgDisabled: l(bgDisabled, other.bgDisabled),
      bgHover: l(bgHover, other.bgHover),
      bgInteractive: l(bgInteractive, other.bgInteractive),
      bgHighlight: l(bgHighlight, other.bgHighlight),
      bgHighlightHover: l(bgHighlightHover, other.bgHighlightHover),
      bgOverlay: l(bgOverlay, other.bgOverlay),
      bgOverlayAlpha: d(bgOverlayAlpha, other.bgOverlayAlpha),
      bgSwitchOff: l(bgSwitchOff, other.bgSwitchOff),
      bgSwitchOffHover: l(bgSwitchOffHover, other.bgSwitchOffHover),
      fgBase: l(fgBase, other.fgBase),
      fgSubtle: l(fgSubtle, other.fgSubtle),
      fgMuted: l(fgMuted, other.fgMuted),
      fgDisabled: l(fgDisabled, other.fgDisabled),
      fgOnColor: l(fgOnColor, other.fgOnColor),
      fgOnInverted: l(fgOnInverted, other.fgOnInverted),
      fgInteractive: l(fgInteractive, other.fgInteractive),
      fgInteractiveHover: l(fgInteractiveHover, other.fgInteractiveHover),
      fgError: l(fgError, other.fgError),
      borderBase: l(borderBase, other.borderBase),
      borderStrong: l(borderStrong, other.borderStrong),
      borderInteractive: l(borderInteractive, other.borderInteractive),
      borderError: l(borderError, other.borderError),
      borderDanger: l(borderDanger, other.borderDanger),
      borderMenuTop: l(borderMenuTop, other.borderMenuTop),
      borderMenuBot: l(borderMenuBot, other.borderMenuBot),
      buttonNeutral: l(buttonNeutral, other.buttonNeutral),
      buttonNeutralHover: l(buttonNeutralHover, other.buttonNeutralHover),
      buttonNeutralPressed: l(buttonNeutralPressed, other.buttonNeutralPressed),
      buttonInverted: l(buttonInverted, other.buttonInverted),
      buttonInvertedHover: l(buttonInvertedHover, other.buttonInvertedHover),
      buttonInvertedPressed: l(
        buttonInvertedPressed,
        other.buttonInvertedPressed,
      ),
      buttonDanger: l(buttonDanger, other.buttonDanger),
      buttonDangerHover: l(buttonDangerHover, other.buttonDangerHover),
      buttonDangerPressed: l(buttonDangerPressed, other.buttonDangerPressed),
      buttonTransparentHover: l(
        buttonTransparentHover,
        other.buttonTransparentHover,
      ),
      buttonTransparentPressed: l(
        buttonTransparentPressed,
        other.buttonTransparentPressed,
      ),
      tagNeutralBg: l(tagNeutralBg, other.tagNeutralBg),
      tagNeutralBgHover: l(tagNeutralBgHover, other.tagNeutralBgHover),
      tagNeutralText: l(tagNeutralText, other.tagNeutralText),
      tagNeutralIcon: l(tagNeutralIcon, other.tagNeutralIcon),
      tagNeutralBorder: l(tagNeutralBorder, other.tagNeutralBorder),
      tagBlueBg: l(tagBlueBg, other.tagBlueBg),
      tagBlueBgHover: l(tagBlueBgHover, other.tagBlueBgHover),
      tagBlueText: l(tagBlueText, other.tagBlueText),
      tagBlueIcon: l(tagBlueIcon, other.tagBlueIcon),
      tagBlueBorder: l(tagBlueBorder, other.tagBlueBorder),
      tagGreenBg: l(tagGreenBg, other.tagGreenBg),
      tagGreenBgHover: l(tagGreenBgHover, other.tagGreenBgHover),
      tagGreenText: l(tagGreenText, other.tagGreenText),
      tagGreenIcon: l(tagGreenIcon, other.tagGreenIcon),
      tagGreenBorder: l(tagGreenBorder, other.tagGreenBorder),
      tagOrangeBg: l(tagOrangeBg, other.tagOrangeBg),
      tagOrangeBgHover: l(tagOrangeBgHover, other.tagOrangeBgHover),
      tagOrangeText: l(tagOrangeText, other.tagOrangeText),
      tagOrangeIcon: l(tagOrangeIcon, other.tagOrangeIcon),
      tagOrangeBorder: l(tagOrangeBorder, other.tagOrangeBorder),
      tagRedBg: l(tagRedBg, other.tagRedBg),
      tagRedBgHover: l(tagRedBgHover, other.tagRedBgHover),
      tagRedText: l(tagRedText, other.tagRedText),
      tagRedIcon: l(tagRedIcon, other.tagRedIcon),
      tagRedBorder: l(tagRedBorder, other.tagRedBorder),
      tagPurpleBg: l(tagPurpleBg, other.tagPurpleBg),
      tagPurpleBgHover: l(tagPurpleBgHover, other.tagPurpleBgHover),
      tagPurpleText: l(tagPurpleText, other.tagPurpleText),
      tagPurpleIcon: l(tagPurpleIcon, other.tagPurpleIcon),
      tagPurpleBorder: l(tagPurpleBorder, other.tagPurpleBorder),
      tagAmberBg: l(tagAmberBg, other.tagAmberBg),
      tagAmberBgHover: l(tagAmberBgHover, other.tagAmberBgHover),
      tagAmberText: l(tagAmberText, other.tagAmberText),
      tagAmberIcon: l(tagAmberIcon, other.tagAmberIcon),
      tagAmberBorder: l(tagAmberBorder, other.tagAmberBorder),
      contrastBgBase: l(contrastBgBase, other.contrastBgBase),
      contrastBgBaseHover: l(contrastBgBaseHover, other.contrastBgBaseHover),
      contrastBgBasePressed: l(
        contrastBgBasePressed,
        other.contrastBgBasePressed,
      ),
      contrastBgSubtle: l(contrastBgSubtle, other.contrastBgSubtle),
      contrastFgPrimary: l(contrastFgPrimary, other.contrastFgPrimary),
      contrastFgPrimaryAlpha: d(
        contrastFgPrimaryAlpha,
        other.contrastFgPrimaryAlpha,
      ),
      contrastFgSecondary: l(contrastFgSecondary, other.contrastFgSecondary),
      contrastFgSecondaryAlpha: d(
        contrastFgSecondaryAlpha,
        other.contrastFgSecondaryAlpha,
      ),
      contrastBorderBase: l(contrastBorderBase, other.contrastBorderBase),
      contrastBorderBaseAlpha: d(
        contrastBorderBaseAlpha,
        other.contrastBorderBaseAlpha,
      ),
    );
  }
}

/// Convenience accessor: `context.themeColors.bgBase`. Reads the active
/// `AppColors` extension from the current `ThemeData`. Throws (in debug)
/// if the extension wasn't installed by `ThemeManager` — that's the
/// signal that the theme wasn't built via this project's ThemeManager.
extension AppColorsContext on BuildContext {
  AppColors get appColors {
    final ext = Theme.of(this).extension<AppColors>();
    assert(
      ext != null,
      'AppColors not installed on ThemeData — make sure ThemeManager built '
      'the active theme.',
    );
    return ext ?? AppColors.light;
  }
}
