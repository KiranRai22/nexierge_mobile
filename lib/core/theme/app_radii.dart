import 'package:flutter/material.dart';

/// Radius scale ported from `--radius-*` in the React design system. These
/// don't change between light and dark themes today, but they're a
/// `ThemeExtension` so the design system can override per-brand or
/// per-platform later without touching widget code.
@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  /// `--radius-sm: 6px`
  final double sm;

  /// `--radius-md: 8px` — also the shadcn fallback `--radius`.
  final double md;

  /// `--radius-lg: 10px`
  final double lg;

  /// `--radius-xl: 14px`
  final double xl;

  /// `--radius-full: 9999px` — pill shapes.
  final double full;

  const AppRadii({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  static const AppRadii standard = AppRadii(
    sm: 6,
    md: 8,
    lg: 10,
    xl: 14,
    full: 9999,
  );

  /// Pre-built `BorderRadius.circular(...)` for ergonomic widget code.
  BorderRadius get smR => BorderRadius.circular(sm);
  BorderRadius get mdR => BorderRadius.circular(md);
  BorderRadius get lgR => BorderRadius.circular(lg);
  BorderRadius get xlR => BorderRadius.circular(xl);
  BorderRadius get fullR => BorderRadius.circular(full);

  @override
  AppRadii copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? full,
  }) {
    return AppRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      full: full ?? this.full,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    double d(double a, double b) => a + (b - a) * t;
    return AppRadii(
      sm: d(sm, other.sm),
      md: d(md, other.md),
      lg: d(lg, other.lg),
      xl: d(xl, other.xl),
      full: d(full, other.full),
    );
  }
}

extension AppRadiiContext on BuildContext {
  AppRadii get appRadii =>
      Theme.of(this).extension<AppRadii>() ?? AppRadii.standard;
}
