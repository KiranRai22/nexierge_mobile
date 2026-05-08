import 'package:flutter/material.dart';

import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/widgets/shimmer_widget.dart';

/// Skeleton card mirroring [TicketCardNew]'s shape:
/// avatar circle on the left, two stacked text lines, action pill on the
/// right. Sized to ~92dp so the layout doesn't jump when real cards arrive.
class TicketCardSkeleton extends StatelessWidget {
  const TicketCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderBase),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerCircle(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ShimmerText(width: 70, height: 14),
                    SizedBox(width: 8),
                    ShimmerContainer(width: 48, height: 18, borderRadius: 999),
                  ],
                ),
                const SizedBox(height: 8),
                const ShimmerText(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                const ShimmerText(width: 140, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ShimmerContainer(width: 88, height: 32, borderRadius: 8),
        ],
      ),
    );
  }
}

/// Vertical list of ticket-card skeletons. Used as the initial loading
/// state for any tickets list (Incoming, Today, Done).
class TicketListSkeleton extends StatelessWidget {
  final int count;
  const TicketListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: count,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: TicketCardSkeleton(),
      ),
    );
  }
}

/// Single ticket-card skeleton inside its own row padding — used as the
/// pagination loader at the tail of an infinite-scroll list.
class TicketPaginationSkeleton extends StatelessWidget {
  const TicketPaginationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TicketCardSkeleton(),
    );
  }
}

/// Generic picker-sheet row skeleton — short circle + line. Reused by
/// the department picker, filter sheet, and room picker.
class PickerListSkeleton extends StatelessWidget {
  final int count;
  final bool showLeadingCircle;
  const PickerListSkeleton({
    super.key,
    this.count = 6,
    this.showLeadingCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: count,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              if (showLeadingCircle) ...[
                const ShimmerCircle(size: 28),
                const SizedBox(width: 12),
              ],
              const Expanded(child: ShimmerText(width: double.infinity, height: 14)),
              const SizedBox(width: 12),
              const ShimmerContainer(width: 18, height: 18, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton grid for catalog item lists (universal request, paid catalog).
class CatalogGridSkeleton extends StatelessWidget {
  final int count;
  const CatalogGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: c.bgBase,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderBase),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: ShimmerContainer(
                width: double.infinity,
                borderRadius: 10,
              ),
            ),
            SizedBox(height: 10),
            ShimmerText(width: 120, height: 14),
            SizedBox(height: 6),
            ShimmerText(width: 60, height: 12),
          ],
        ),
      ),
    );
  }
}
