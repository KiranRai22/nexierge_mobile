import 'package:flutter/material.dart';

import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/widgets/shimmer_widget.dart';

/// Animated skeleton for the ticket detail screen. Mirrors the real
/// layout: app bar → tabs → hero card → info card → action bar.
class TicketDetailSkeleton extends StatelessWidget {
  const TicketDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: Column(
        children: [
          _AppBar(c: c),
          _Tabs(c: c),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _HeroCard(),
                SizedBox(height: 16),
                _InfoCard(),
                SizedBox(height: 16),
                _RequestRows(),
              ],
            ),
          ),
          _ActionBar(c: c),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final AppColors c;
  const _AppBar({required this.c});

  @override
  Widget build(BuildContext context) {
    // Mirror the real `TicketDetailAppBar` (which wraps in
    // `SafeArea(bottom: false)`) so the skeleton doesn't render under the
    // status bar / notch on cold-start.
    return Material(
      color: c.bgBase,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.bgBase,
            border: Border(bottom: BorderSide(color: c.borderBase)),
          ),
          child: const Row(
            children: [
              ShimmerCircle(size: 36),
              SizedBox(width: 12),
              Expanded(child: ShimmerText(width: 120, height: 18)),
              SizedBox(width: 12),
              ShimmerCircle(size: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final AppColors c;
  const _Tabs({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.bgBase,
        border: Border(bottom: BorderSide(color: c.borderBase)),
      ),
      child: Row(
        children: const [
          Expanded(child: ShimmerContainer(height: 28, borderRadius: 999)),
          SizedBox(width: 16),
          Expanded(child: ShimmerContainer(height: 28, borderRadius: 999)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderBase),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              ShimmerCircle(size: 32),
              SizedBox(width: 10),
              ShimmerText(width: 90, height: 14),
              Spacer(),
              ShimmerContainer(width: 64, height: 22, borderRadius: 999),
            ],
          ),
          const SizedBox(height: 14),
          const ShimmerText(width: double.infinity, height: 18),
          const SizedBox(height: 8),
          const ShimmerText(width: 200, height: 14),
          const SizedBox(height: 14),
          Row(
            children: const [
              ShimmerContainer(width: 90, height: 28, borderRadius: 999),
              SizedBox(width: 8),
              ShimmerContainer(width: 70, height: 28, borderRadius: 999),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderBase),
      ),
      child: Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: const [
                ShimmerCircle(size: 18),
                SizedBox(width: 10),
                ShimmerText(width: 80, height: 12),
                Spacer(),
                ShimmerText(width: 100, height: 12),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestRows extends StatelessWidget {
  const _RequestRows();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderBase),
      ),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: const [
                ShimmerContainer(width: 36, height: 36, borderRadius: 8),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerText(width: 140, height: 14),
                      SizedBox(height: 6),
                      ShimmerText(width: 80, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                ShimmerText(width: 30, height: 14),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final AppColors c;
  const _ActionBar({required this.c});

  @override
  Widget build(BuildContext context) {
    // Mirror the real `TicketActionBar` (which wraps in
    // `SafeArea(top: false, minimum: EdgeInsets.fromLTRB(16, 8, 16, 12))`)
    // so the skeleton doesn't sit under the home indicator on iOS.
    return Material(
      color: c.bgBase,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bgBase,
          border: Border(top: BorderSide(color: c.borderBase)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              const ShimmerContainer(
                width: double.infinity,
                height: 48,
                borderRadius: 12,
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Expanded(child: ShimmerContainer(height: 44, borderRadius: 10)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerContainer(height: 44, borderRadius: 10)),
                  SizedBox(width: 8),
                  Expanded(child: ShimmerContainer(height: 44, borderRadius: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
