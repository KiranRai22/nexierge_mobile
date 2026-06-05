import 'package:flutter/material.dart';

abstract class ColorPalette {
  // Primary brand
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryLight = Color(0xFFFCE4EC);
  static const Color primaryDark = Color(0xFFAD1457);
  static const Color primarySoftTint = Color(0xFFFDE8F1);

  // Secondary brand
  static const Color secondary = Color(0xFF34A853);
  static const Color secondaryLight = Color(0xFF66BB6A);
  static const Color secondaryDark = Color(0xFF1B5E20);

  // Accent
  static const Color accent = Color(0xFFFBBC04);
  static const Color accentLight = Color(0xFFFFE082);
  static const Color accentDark = Color(0xFFF57F17);

  // Semantic
  static const Color error = Color(0xFFEA4335);
  static const Color success = Color(0xFF34A853);
  static const Color successTint = Color(0xFFD8F4E2);
  static const Color successBorder = Color(0xFF34A853);
  static const Color successText = Color(0xFF1B7A3A);
  static const Color warning = Color(0xFFFBBC04);
  static const Color info = Color(0xFF1A73E8);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Divider / Border
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);

  // Form field & segmented control surfaces
  static const Color inputBackground = Color(0xFFEFEFFB);
  static const Color segmentedTrack = Color(0xFFF1F1F6);
  static const Color segmentedThumb = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Login (always-light) screen tokens
  // ---------------------------------------------------------------------------
  static const Color loginBgTop = Color(0xFFEFE8FF);
  static const Color loginBgBottom = Color(0xFFFFFFFF);
  static const Color loginCardBg = Color(0xFFFFFFFF);
  static const Color loginCardBorder = Color(0x1A000000);
  static const Color loginDivider = Color(0x1A000000);
  static const Color loginLogoBg = Color(0xFFE8E5F0);
  static const Color loginLogoBorder = Color(0x1A000000);
  static const Color loginLogoIcon = Color(0xFF6B5FA0);
  static const Color loginTitle = Color(0xFF1A1025);
  static const Color loginSubtitle = Color(0xFF6B6082);
  static const Color loginFieldLabel = Color(0xFF2D2540);
  static const Color loginRequiredAsterisk = Color(0xFFE91E63);
  static const Color loginTabTrack = Color(0xFFF0EDF8);
  static const Color loginTabBorder = Color(0xFFDDD9E8);
  static const Color loginTabSelectedBg = Color(0xFFFFFFFF);
  static const Color loginTabSelectedFg = Color(0xFF1A1025);
  static const Color loginTabUnselectedFg = Color(0xFF9A93AE);
  static const Color loginInputBg = Color(0xFFF5F3FA);
  static const Color loginInputBorder = Color(0x24000000);
  static const Color loginInputIcon = Color(0xFF9A93AE);
  static const Color loginInputText = Color(0xFF1A1025);
  static const Color loginInputHint = Color(0xFFB0ABBE);
  static const Color loginInputDivider = Color(0x1F000000);
  static const Color loginButtonDisabledBg = Color(0xFFE5E1F0);
  static const Color loginButtonDisabledFg = Color(0xFF9A93AE);
  static const Color loginFooterText = Color(0xFF9A93AE);

  // ---------------------------------------------------------------------------
  // HotelOps (Tickets / Activity) design tokens
  // Source: hotel-ops.lovable.app prototype (captured 2026-04-25).
  // Use these in /features/tickets, /features/activity, /features/shell.
  // ---------------------------------------------------------------------------

  // Brand
  static const Color opsPurple = Color(0xFF7B5CFF);
  static const Color opsPurpleDark = Color(0xFF5C3BE5);
  static const Color opsPurpleTint = Color(0xFFEFE8FF);
  static const Color opsPurpleSoft = Color(0xFFF6F1FF);

  // KPI strip card backgrounds
  static const Color kpiNeutralTint = Color(0xFFF6F4FB);
  static const Color kpiOverdueTint = Color(0xFFFBE7EB);
  static const Color kpiOverdueText = Color(0xFFD7263D);

  // Ticket card stripe (left rail)
  static const Color ticketStripeUniversal = Color(0xFF7B5CFF);
  static const Color ticketStripeInProgress = Color(0xFF7B5CFF);
  static const Color ticketStripeDone = Color(0xFF21B26A);
  static const Color ticketStripeOverdue = Color(0xFFD7263D);

  // Ticket type chips
  static const Color chipUniversalBg = Color(0xFFEFE8FF);
  static const Color chipUniversalFg = Color(0xFF5C3BE5);
  static const Color chipCatalogBg = Color(0xFFE6F4FF);
  static const Color chipCatalogFg = Color(0xFF1A6FD9);
  static const Color chipManualBg = Color(0xFFFFE8E1);
  static const Color chipManualFg = Color(0xFFC74A1D);

  // Status accents
  static const Color statusInProgress = Color(0xFF7B5CFF);
  static const Color statusDone = Color(0xFF21B26A);
  static const Color statusOverdue = Color(0xFFD7263D);
  static const Color statusUnassigned = Color(0xFF8B8FA3);

  // Notes / callouts
  static const Color noteCalloutBg = Color(0xFFFFF7CC);
  static const Color noteCalloutFg = Color(0xFF6B5A00);
  static const Color noteCalloutAccent = Color(0xFFE7C800);

  // Page surfaces
  static const Color opsSurface = Color(0xFFFFFFFF);
  static const Color opsSurfaceSubtle = Color(0xFFF7F7FB);
  static const Color opsBorder = Color(0xFFEDEDF3);
  static const Color opsDividerSubtle = Color(0xFFF0F0F4);

  // Sub-tab pill (Incoming / Today / Scheduled / Done)
  static const Color subTabBg = Color(0xFFF1F1F6);
  static const Color subTabActiveBg = Color(0xFF111322);
  static const Color subTabActiveFg = Color(0xFFFFFFFF);
  static const Color subTabInactiveFg = Color(0xFF6B7180);

  // Activity row icon tints
  static const Color activityCreatedBg = Color(0xFFEDEDF3);
  static const Color activityCreatedFg = Color(0xFF6B7180);
  static const Color activityAcceptedBg = Color(0xFFEFE8FF);
  static const Color activityAcceptedFg = Color(0xFF5C3BE5);
  static const Color activityDoneBg = Color(0xFFD9F5E5);
  static const Color activityDoneFg = Color(0xFF159B5A);
  static const Color activityOverdueBg = Color(0xFFFBE7EB);
  static const Color activityOverdueFg = Color(0xFFD7263D);
  static const Color activityCancelledBg = Color(0xFFEDEDF3);
  static const Color activityCancelledFg = Color(0xFF8B8FA3);
  static const Color activityNoteBg = Color(0xFFFFF7CC);
  static const Color activityNoteFg = Color(0xFF8A6E00);
  static const Color activityReassignedBg = Color(0xFFE6F4FF);
  static const Color activityReassignedFg = Color(0xFF1A6FD9);

  // Universal create item tile
  static const Color itemTileBg = Color(0xFFF7F7FB);
  static const Color itemTileBorder = Color(0xFFEDEDF3);
  static const Color itemTileSelectedBg = Color(0xFFEFE8FF);
  static const Color itemTileSelectedBorder = Color(0xFF7B5CFF);

  // Bottom nav
  static const Color bottomNavSurface = Color(0xFFFFFFFF);
  static const Color bottomNavInactive = Color(0xFF8B8FA3);
  static const Color bottomNavActive = Color(0xFF7B5CFF);
}
