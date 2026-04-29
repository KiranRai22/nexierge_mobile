import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/widgets/shimmer_widget.dart';

/// Profile tab — old version kept for reference. See profile_screen.dart for
/// the current implementation.
class ProfileScreenOld extends ConsumerStatefulWidget {
  const ProfileScreenOld({super.key});

  @override
  ConsumerState<ProfileScreenOld> createState() => _ProfileScreenOldState();
}

class _ProfileScreenOldState extends ConsumerState<ProfileScreenOld> {
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return Container(
      color: c.bgSubtle,
      child: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            return _ProfileShimmer();
          },
        ),
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header shimmer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: c.bgBase,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderBase),
            ),
            child: Column(
              children: [
                ShimmerCircle(size: 80),
                const SizedBox(height: 16),
                ShimmerText(width: 150, height: 20),
                const SizedBox(height: 8),
                ShimmerText(width: 100, height: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Info sections shimmer
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              // Account info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.bgBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderBase),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 120, height: 16),
                    const SizedBox(height: 12),
                    ...List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ShimmerText(width: 80, height: 14),
                            const Spacer(),
                            ShimmerText(width: 100, height: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Work info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.bgBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderBase),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 100, height: 16),
                    const SizedBox(height: 12),
                    ...List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ShimmerText(width: 60, height: 14),
                            const Spacer(),
                            ShimmerText(width: 80, height: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Preferences section
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: ShimmerText(width: 80, height: 12),
              ),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: c.bgBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderBase),
                ),
                child: const ShimmerContainer(),
              ),
              const SizedBox(height: 12),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: c.bgBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderBase),
                ),
                child: const ShimmerContainer(),
              ),
              const SizedBox(height: 24),
              // Logout button shimmer
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: c.bgBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderBase),
                ),
                child: const ShimmerContainer(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
