import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_palette.dart';

abstract class TypographyManager {
  // Display
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textPrimary,
      );

  // Headline
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ColorPalette.textPrimary,
      );

  // Title
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: ColorPalette.textPrimary,
      );

  // Body
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: ColorPalette.textSecondary,
      );

  // Label
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: ColorPalette.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: ColorPalette.textSecondary,
      );

  // ---------------------------------------------------------------------------
  // HotelOps presets (KPI counts, section headers, ALL-CAPS overlines).
  // ---------------------------------------------------------------------------

  /// Big number used inside KPI cards (Incoming / In Progress / Overdue).
  static TextStyle get kpiCount => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: ColorPalette.textPrimary,
      );

  /// Hero count used in the dashboard's wide *Incoming Now* card.
  static TextStyle get kpiHeroCount => GoogleFonts.inter(
        fontSize: 44,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.5,
        color: ColorPalette.textPrimary,
      );

  /// ALL-CAPS label under KPI count.
  static TextStyle get kpiLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: ColorPalette.textSecondary,
      );

  /// ALL-CAPS section header used between groups (`INCOMING NOW · 2`).
  static TextStyle get sectionOverline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ColorPalette.textSecondary,
      );

  /// Ticket card title.
  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: ColorPalette.textPrimary,
      );

  /// Ticket card meta (room / dept / time).
  static TextStyle get cardMeta => GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: ColorPalette.textSecondary,
      );

  /// Tab / chip text.
  static TextStyle get tabText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ColorPalette.textPrimary,
      );

  /// Title of the screen in the top app bar (e.g. `TKT-3042`).
  static TextStyle get screenTitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: ColorPalette.textPrimary,
      );
}
