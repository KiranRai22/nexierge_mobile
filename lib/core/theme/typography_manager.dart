import 'package:flutter/material.dart';

import 'color_palette.dart';

abstract class TypographyManager {
  /// Single source of truth for the app's UI typeface. Bundled locally —
  /// see `assets/fonts/Geist/` and the `fonts:` block in `pubspec.yaml`.
  /// Geist (Vercel, SIL OFL-1.1) was added in lockstep with the Medusa
  /// design-system port (`docs/ai_prompts/index.css`).
  static const String _fontFamily = 'Geist';

  /// Internal builder so every preset shares the same font family. Swap
  /// `_fontFamily` to switch the entire app's UI typeface.
  static TextStyle _t({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double letterSpacing = 0,
    Color color = ColorPalette.textPrimary,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // Display
  static TextStyle get displayLarge => _t(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      );

  static TextStyle get displayMedium =>
      _t(fontSize: 45, fontWeight: FontWeight.w400);

  static TextStyle get displaySmall =>
      _t(fontSize: 36, fontWeight: FontWeight.w400);

  // Headline
  static TextStyle get headlineLarge =>
      _t(fontSize: 32, fontWeight: FontWeight.w600);

  static TextStyle get headlineMedium =>
      _t(fontSize: 28, fontWeight: FontWeight.w600);

  static TextStyle get headlineSmall =>
      _t(fontSize: 24, fontWeight: FontWeight.w600);

  // Title
  static TextStyle get titleLarge =>
      _t(fontSize: 22, fontWeight: FontWeight.w500);

  static TextStyle get titleMedium => _t(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => _t(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  // Body
  static TextStyle get bodyLarge => _t(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyMedium => _t(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => _t(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: ColorPalette.textSecondary,
      );

  // Label
  static TextStyle get labelLarge => _t(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _t(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => _t(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: ColorPalette.textSecondary,
      );

  // ---------------------------------------------------------------------------
  // HotelOps presets (KPI counts, section headers, ALL-CAPS overlines).
  // ---------------------------------------------------------------------------

  /// Big number used inside KPI cards (Incoming / In Progress / Overdue).
  static TextStyle get kpiCount => _t(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );

  /// Hero count used in the dashboard's wide *Incoming Now* card.
  static TextStyle get kpiHeroCount => _t(
        fontSize: 44,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.5,
      );

  /// ALL-CAPS label under KPI count.
  static TextStyle get kpiLabel => _t(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: ColorPalette.textSecondary,
      );

  /// ALL-CAPS section header used between groups (`INCOMING NOW · 2`).
  static TextStyle get sectionOverline => _t(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ColorPalette.textSecondary,
      );

  /// Ticket card title.
  static TextStyle get cardTitle => _t(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  /// Ticket card meta (room / dept / time).
  static TextStyle get cardMeta => _t(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textSecondary,
      );

  /// Tab / chip text.
  static TextStyle get tabText =>
      _t(fontSize: 13, fontWeight: FontWeight.w500);

  /// Title of the screen in the top app bar (e.g. `TKT-3042`).
  static TextStyle get screenTitle => _t(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );

  // ---------------------------------------------------------------------------
  // Medusa typography ramp — ports the `.text-*` utility classes from the
  // React design system (`docs/ai_prompts/index.css`). Names map 1:1 so the
  // RN/Web spec drops into Flutter without translation.
  //
  // CSS `line-height` is absolute px; Flutter `height` is a multiplier — so
  // we divide here. Keep this helper in sync if the Medusa scale changes.
  // ---------------------------------------------------------------------------

  static TextStyle _medusa({
    required double fontSize,
    required double height,
    required FontWeight fontWeight,
    double letterSpacing = 0,
  }) =>
      _t(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height / fontSize,
        letterSpacing: letterSpacing,
      );

  /// `.text-display` — 24/30, w700, -0.01em.
  static TextStyle get textDisplay => _medusa(
        fontSize: 24,
        height: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.24,
      );

  /// `.text-title` — 20/26, w700, -0.01em.
  static TextStyle get textTitle => _medusa(
        fontSize: 20,
        height: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.20,
      );

  /// `.text-heading` — 17/24, w600.
  static TextStyle get textHeading =>
      _medusa(fontSize: 17, height: 24, fontWeight: FontWeight.w600);

  /// `.text-body-strong` — 15/22, w500.
  static TextStyle get textBodyStrong =>
      _medusa(fontSize: 15, height: 22, fontWeight: FontWeight.w500);

  /// `.text-body` — 15/22, w400. Default body copy.
  static TextStyle get textBody =>
      _medusa(fontSize: 15, height: 22, fontWeight: FontWeight.w400);

  /// `.text-label` — 13/18, w500.
  static TextStyle get textLabel =>
      _medusa(fontSize: 13, height: 18, fontWeight: FontWeight.w500);

  /// `.text-meta` — 13/18, w400.
  static TextStyle get textMeta =>
      _medusa(fontSize: 13, height: 18, fontWeight: FontWeight.w400);

  /// `.text-caption` — 12/16, w500.
  static TextStyle get textCaption =>
      _medusa(fontSize: 12, height: 16, fontWeight: FontWeight.w500);

  /// `.text-micro` — 11/14, w400.
  static TextStyle get textMicro =>
      _medusa(fontSize: 11, height: 14, fontWeight: FontWeight.w400);
}
