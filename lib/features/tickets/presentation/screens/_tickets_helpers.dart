import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

class TicketsFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  const TicketsFilterChip({super.key, 
    required this.label,
    required this.count,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? ColorPalette.opsSurface : ColorPalette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ColorPalette.opsBorder),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TypographyManager.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ColorPalette.opsPurpleTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TypographyManager.bodySmall.copyWith(
                color: ColorPalette.opsPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
