import 'package:flutter/material.dart';

/// Shadow scale ported from `--shadow-*` in the React design system.
/// Encoded as `BoxShadow` lists ready to drop into `BoxDecoration.boxShadow`.
///
/// CSS uses `rgba(0,0,0,a)`; we use `Colors.black.withValues(alpha: a)`
/// directly. Shadows are theme-aware so dark mode can soften / drop them
/// later — same pattern as `AppColors`.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  /// `--shadow-subtle: 0 1px 2px rgba(0,0,0,0.04)`
  final List<BoxShadow> subtle;

  /// `--shadow-card: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)`
  final List<BoxShadow> card;

  /// `--shadow-sheet: 0 -4px 16px rgba(0,0,0,0.08)` — bottom sheets.
  final List<BoxShadow> sheet;

  /// `--shadow-fab: 0 4px 12px rgba(0,0,0,0.15)` — FAB lift.
  final List<BoxShadow> fab;

  /// `--shadow-modal: 0 8px 32px rgba(0,0,0,0.16)` — modal lift.
  final List<BoxShadow> modal;

  const AppShadows({
    required this.subtle,
    required this.card,
    required this.sheet,
    required this.fab,
    required this.modal,
  });

  static const _black = Color(0xFF000000);

  static final AppShadows light = AppShadows(
    subtle: [
      BoxShadow(
        color: _black.withValues(alpha: 0.04),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    card: [
      BoxShadow(
        color: _black.withValues(alpha: 0.08),
        offset: const Offset(0, 1),
        blurRadius: 3,
      ),
      BoxShadow(
        color: _black.withValues(alpha: 0.04),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    sheet: [
      BoxShadow(
        color: _black.withValues(alpha: 0.08),
        offset: const Offset(0, -4),
        blurRadius: 16,
      ),
    ],
    fab: [
      BoxShadow(
        color: _black.withValues(alpha: 0.15),
        offset: const Offset(0, 4),
        blurRadius: 12,
      ),
    ],
    modal: [
      BoxShadow(
        color: _black.withValues(alpha: 0.16),
        offset: const Offset(0, 8),
        blurRadius: 32,
      ),
    ],
  );

  /// Dark mode dampens shadows — surface elevation in dark UI is sold by
  /// background-lift + hairline borders, not drop shadows. Halving the
  /// alpha keeps the cue subtle on near-black surfaces.
  static final AppShadows dark = AppShadows(
    subtle: [
      BoxShadow(
        color: _black.withValues(alpha: 0.20),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    card: [
      BoxShadow(
        color: _black.withValues(alpha: 0.32),
        offset: const Offset(0, 1),
        blurRadius: 3,
      ),
      BoxShadow(
        color: _black.withValues(alpha: 0.20),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    sheet: [
      BoxShadow(
        color: _black.withValues(alpha: 0.32),
        offset: const Offset(0, -4),
        blurRadius: 16,
      ),
    ],
    fab: [
      BoxShadow(
        color: _black.withValues(alpha: 0.40),
        offset: const Offset(0, 4),
        blurRadius: 12,
      ),
    ],
    modal: [
      BoxShadow(
        color: _black.withValues(alpha: 0.48),
        offset: const Offset(0, 8),
        blurRadius: 32,
      ),
    ],
  );

  @override
  AppShadows copyWith({
    List<BoxShadow>? subtle,
    List<BoxShadow>? card,
    List<BoxShadow>? sheet,
    List<BoxShadow>? fab,
    List<BoxShadow>? modal,
  }) {
    return AppShadows(
      subtle: subtle ?? this.subtle,
      card: card ?? this.card,
      sheet: sheet ?? this.sheet,
      fab: fab ?? this.fab,
      modal: modal ?? this.modal,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    // Shadow lists don't lerp gracefully across different list lengths;
    // since light/dark both share the same shape per slot, snap at t=0.5.
    if (other is! AppShadows) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppShadowsContext on BuildContext {
  AppShadows get appShadows =>
      Theme.of(this).extension<AppShadows>() ?? AppShadows.light;
}
