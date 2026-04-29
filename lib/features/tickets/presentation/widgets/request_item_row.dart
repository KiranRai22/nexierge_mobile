import 'package:flutter/material.dart';

import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Row for request items with icon, name, subtitle, and quantity
/// Matches TSX RequestItemRow design
class RequestItemRow extends StatelessWidget {
  final Widget icon;
  final String name;
  final String? subtitle;
  final int quantity;
  final bool isLast;

  const RequestItemRow({
    super.key,
    required this.icon,
    required this.name,
    this.subtitle,
    required this.quantity,
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
        children: [
          // Icon container
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.bgHover,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(color: c.fgSubtle, size: 18),
                child: icon,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TypographyManager.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.fgBase,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.fgMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Quantity
          Text(
            '×$quantity',
            style: TypographyManager.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: c.fgSubtle,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
