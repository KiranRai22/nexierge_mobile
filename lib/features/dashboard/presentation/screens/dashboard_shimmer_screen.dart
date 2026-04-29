import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_palette.dart';
import '../providers/dashboard_bootstrap_controller.dart';
import '../widgets/shimmer_widget.dart';

/// Shimmer loading screen shown during dashboard bootstrap.
/// Mimics the dashboard layout so the transition feels seamless.
class DashboardShimmerScreen extends ConsumerWidget {
  const DashboardShimmerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(dashboardBootstrapControllerProvider);
    final progress = bootstrap.valueOrNull?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator at top
            _ProgressIndicator(progress: progress),

            // Shimmer content matching dashboard layout
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header shimmer (avatar + greeting + bell)
                    const _HeaderShimmer(),
                    const SizedBox(height: 24),

                    // Greeting text shimmer
                    const _GreetingShimmer(),
                    const SizedBox(height: 24),

                    // Stats grid shimmer (2x2 cards)
                    const _StatsGridShimmer(),
                    const SizedBox(height: 24),

                    // Needs attention section shimmer
                    const _NeedsAttentionShimmer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation bar shimmer
      bottomNavigationBar: const _BottomNavShimmer(),
      // Floating action button shimmer
      floatingActionButton: const _FabShimmer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Progress indicator showing bootstrap completion percentage
class _ProgressIndicator extends StatelessWidget {
  final double progress;

  const _ProgressIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress > 0 ? progress : null, // Indeterminate if 0
          backgroundColor: ColorPalette.chipUniversalBg,
          valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.loginTitle),
          minHeight: 2,
        ),
        if (progress > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  color: ColorPalette.loginSubtitle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Header shimmer: avatar + name + bell icon
class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar shimmer
        const ShimmerCircle(size: 40),
        const SizedBox(width: 12),

        // Name and department shimmer
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerText(width: 150, height: 18),
              const SizedBox(height: 6),
              ShimmerText(width: 100, height: 12),
            ],
          ),
        ),

        // Theme toggle + Bell icons shimmer
        Row(
          children: [
            ShimmerCircle(size: 32),
            const SizedBox(width: 8),
            ShimmerCircle(size: 32),
          ],
        ),
      ],
    );
  }
}

/// Greeting text shimmer
class _GreetingShimmer extends StatelessWidget {
  const _GreetingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerText(width: 200, height: 28),
        const SizedBox(height: 8),
        ShimmerText(width: 180, height: 16),
      ],
    );
  }
}

/// Stats grid shimmer (2x2 cards)
class _StatsGridShimmer extends StatelessWidget {
  const _StatsGridShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCardShimmer()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardShimmer()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCardShimmer()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardShimmer()),
          ],
        ),
      ],
    );
  }
}

/// Single stat card shimmer
class _StatCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerContainer(
      height: 80,
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerText(width: 40, height: 24),
          const SizedBox(height: 8),
          ShimmerText(width: 80, height: 14),
        ],
      ),
    );
  }
}

/// Needs attention section shimmer
class _NeedsAttentionShimmer extends StatelessWidget {
  const _NeedsAttentionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        ShimmerText(width: 140, height: 18),
        const SizedBox(height: 12),

        // Ticket items shimmer (3 items)
        _TicketItemShimmer(),
        const SizedBox(height: 8),
        _TicketItemShimmer(),
        const SizedBox(height: 8),
        _TicketItemShimmer(),
      ],
    );
  }
}

/// Single ticket item row shimmer
class _TicketItemShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerContainer(
      height: 64,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Status dot shimmer
          ShimmerCircle(size: 8),
          const SizedBox(width: 12),

          // Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerText(width: 120, height: 14),
                const SizedBox(height: 6),
                ShimmerText(width: 80, height: 12),
              ],
            ),
          ),

          // Arrow shimmer
          ShimmerCircle(size: 24),
        ],
      ),
    );
  }
}

/// Bottom navigation bar shimmer - matches HomeShell's bottom nav
class _BottomNavShimmer extends StatelessWidget {
  const _BottomNavShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home tab shimmer
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerCircle(size: 24),
              const SizedBox(height: 4),
              ShimmerText(width: 40, height: 10),
            ],
          ),
          // Tickets tab shimmer
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerCircle(size: 24),
              const SizedBox(height: 4),
              ShimmerText(width: 40, height: 10),
            ],
          ),
          // Profile tab shimmer
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerCircle(size: 24),
              const SizedBox(height: 4),
              ShimmerText(width: 40, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Floating action button shimmer - centered docked FAB
class _FabShimmer extends StatelessWidget {
  const _FabShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerCircle(size: 56);
  }
}
