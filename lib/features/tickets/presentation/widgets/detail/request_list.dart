import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../domain/models/ticket.dart';

/// `REQUEST` block: section overline + each item as a small tile.
class RequestList extends StatelessWidget {
  final List<RequestItem> items;
  const RequestList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.detailRequestLabel,
          style: TypographyManager.sectionOverline,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) ...[
          _ItemRow(item: items[i]),
          if (i != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final RequestItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: ColorPalette.itemTileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.itemTileBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: TypographyManager.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: TypographyManager.bodySmall),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ColorPalette.opsSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: ColorPalette.opsBorder),
            ),
            child: Text(
              '×${item.quantity}',
              style: TypographyManager.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
