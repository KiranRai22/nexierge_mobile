import 'package:flutter/material.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/app_colors.dart';

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
        color: selected ? context.appColors.bgBase : context.appColors.fgOnBrand,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.appColors.borderBase),
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
              color: context.appColors.brandPrimaryTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TypographyManager.bodySmall.copyWith(
                color: context.appColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
