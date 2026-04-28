import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Consistent elevation and shadow styling for cards throughout the app
class CardDecoration {
  /// Standard card elevation with subtle shadow for 3D effect
  static BoxDecoration standard({
    required AppColors colors,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? colors.bgBase,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? colors.borderBase),
      boxShadow: [
        // Main shadow
        BoxShadow(
          color: colors.borderBase.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        // Ambient shadow
        BoxShadow(
          color: colors.borderBase.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
        // Subtle base shadow
        BoxShadow(
          color: colors.borderBase.withValues(alpha: 0.02),
          offset: const Offset(0, 0),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Elevated card with more prominent shadow
  static BoxDecoration elevated({
    required AppColors colors,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? colors.bgBase,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? colors.borderBase),
      boxShadow: [
        // Main shadow
        BoxShadow(
          color: colors.borderBase.withValues(alpha: 0.12),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        // Ambient shadow
        BoxShadow(
          color: colors.borderBase.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
        // Subtle base shadow
        BoxShadow(
          color: colors.borderBase.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Subtle card with minimal shadow
  static BoxDecoration subtle({
    required AppColors colors,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? colors.bgBase,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? colors.borderBase),
      boxShadow: [
        // Subtle shadow
        BoxShadow(
          color: colors.borderBase.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ],
    );
  }
}
