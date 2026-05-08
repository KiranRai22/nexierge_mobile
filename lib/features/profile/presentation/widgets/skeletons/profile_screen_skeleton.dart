import 'package:flutter/material.dart';

import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/widgets/shimmer_widget.dart';

/// Skeleton for the profile screen — header card with avatar + name,
/// then 3 section card placeholders.
class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header: avatar + name + role
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderBase),
          ),
          child: Row(
            children: const [
              ShimmerCircle(size: 64),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 160, height: 18),
                    SizedBox(height: 8),
                    ShimmerText(width: 110, height: 13),
                    SizedBox(height: 6),
                    ShimmerText(width: 80, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Section: details rows
        _SectionCard(rowCount: 4),
        const SizedBox(height: 16),
        _SectionCard(rowCount: 3),
        const SizedBox(height: 16),
        _SectionCard(rowCount: 2),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int rowCount;
  const _SectionCard({required this.rowCount});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBase),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              ShimmerText(width: 120, height: 14),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rowCount; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: const [
                ShimmerCircle(size: 22),
                SizedBox(width: 12),
                ShimmerText(width: 90, height: 13),
                Spacer(),
                ShimmerText(width: 130, height: 13),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
