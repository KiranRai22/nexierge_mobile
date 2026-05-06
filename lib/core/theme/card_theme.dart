import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Consistent elevation and shadow styling for cards throughout the app
class CardDecoration {
  /// Standard card elevation with enhanced shadow and grayish border for better visibility
  static BoxDecoration standard({
    required AppColors colors,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? colors.bgBase,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? colors.borderBase.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: [
        // Main shadow - more prominent
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          offset: const Offset(0, 2),
          blurRadius: 40,
          spreadRadius: 1,
        ),
        // Ambient shadow - enhanced
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          offset: const Offset(0, 5),
          blurRadius: 6,
          spreadRadius: 1,
        ),
        // Subtle base shadow - more noticeable
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Elevated card with very prominent shadow and enhanced grayish border
  static BoxDecoration elevated({
    required AppColors colors,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? colors.bgBase,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? colors.borderBase.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        // Main shadow - very prominent
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        // Ambient shadow - enhanced
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          offset: const Offset(0, 3),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        // Subtle base shadow - more noticeable
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Subtle card with enhanced shadow and grayish border for better visibility
  static BoxDecoration subtle({
    required AppColors colors,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? colors.bgBase,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? colors.borderBase.withValues(alpha: 0.25),
        width: 1.0,
      ),
      boxShadow: [
        // Enhanced subtle shadow
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
        // Additional subtle shadow
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          offset: const Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ],
    );
  }
}
