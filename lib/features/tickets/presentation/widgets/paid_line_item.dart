import 'package:flutter/material.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Line item for paid tickets with name, quantity, modifiers, and price
/// Matches TSX PaidLineItem design
class PaidLineItem extends StatelessWidget {
  final String name;
  final int quantity;
  final String? modifiers;
  final String price;
  final bool isLast;

  const PaidLineItem({
    super.key,
    required this.name,
    required this.quantity,
    this.modifiers,
    required this.price,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: c.borderBase),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name, quantity, modifiers
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TypographyManager.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.fgBase,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '×$quantity',
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                if (modifiers != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    modifiers!,
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.fgMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Price
          Text(
            price,
            style: TypographyManager.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: c.fgBase,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Total row for paid tickets with border top
/// Matches TSX PaidTotal design
class PaidTotal extends StatelessWidget {
  final String total;

  const PaidTotal({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderBase),
        ),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: TypographyManager.labelSmall.copyWith(
              color: c.fgMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            total,
            style: TypographyManager.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: c.fgBase,
              letterSpacing: -0.02,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
