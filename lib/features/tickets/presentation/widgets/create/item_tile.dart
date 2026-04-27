import 'package:flutter/material.dart';

import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../providers/universal_create_controller.dart';

/// One item tile in the Universal create grid. Tap to toggle. When picked,
/// shows a small +/- quantity stepper.
class ItemTile extends StatelessWidget {
  final UniversalItem item;
  final bool selected;
  final int quantity;
  final VoidCallback onToggle;
  final ValueChanged<int> onQuantityChanged;

  const ItemTile({
    super.key,
    required this.item,
    required this.selected,
    required this.quantity,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.title} ${item.subtitle}',
      child: Material(
        color: selected
            ? ColorPalette.itemTileSelectedBg
            : ColorPalette.itemTileBg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? ColorPalette.itemTileSelectedBorder
                    : ColorPalette.itemTileBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: TypographyManager.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TypographyManager.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (selected)
                  _QuantityStepper(
                    value: quantity,
                    onChanged: onQuantityChanged,
                  )
                else
                  _PickHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.add_circle_outline_rounded,
          size: 16,
          color: ColorPalette.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          'Tap to add',
          style: TypographyManager.bodySmall,
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ColorPalette.itemTileSelectedBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: () => onChanged(value - 1),
            enabled: value > 1,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TypographyManager.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () => onChanged(value + 1),
            enabled: value < 99,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 18,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? ColorPalette.opsPurple
              : ColorPalette.textDisabled,
        ),
      ),
    );
  }
}
