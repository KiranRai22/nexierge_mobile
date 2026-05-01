import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../domain/models/catalog.dart';
import '../../screens/create_screen.dart' show formatMoney;

/// Result of customising a catalog item. Returned from the bottom sheet
/// when the user taps "Add to Order". Null = cancelled.
class CatalogCustomizationResult {
  final int quantity;
  final Map<String, Option> selectedOptions;
  final Map<String, int> selectedAddOns;

  const CatalogCustomizationResult({
    this.quantity = 1,
    this.selectedOptions = const {},
    this.selectedAddOns = const {},
  });
}

/// Bottom sheet that lets the user customise a catalog item before
/// adding it to the cart. Pass [initial] to edit an existing line.
class CatalogCustomizerSheet {
  static Future<CatalogCustomizationResult?> show(
    BuildContext context, {
    required CatalogItem item,
    CatalogCustomizationResult? initial,
  }) {
    return showModalBottomSheet<CatalogCustomizationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.opsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CustomizerBody(item: item, initial: initial),
    );
  }
}

class _CustomizerBody extends StatefulWidget {
  final CatalogItem item;
  final CatalogCustomizationResult? initial;
  const _CustomizerBody({required this.item, this.initial});

  @override
  State<_CustomizerBody> createState() => _CustomizerBodyState();
}

class _CustomizerBodyState extends State<_CustomizerBody> {
  late Map<String, Option> _selectedOptions;
  late Map<String, int> _selectedAddOns;

  @override
  void initState() {
    super.initState();
    _selectedOptions = {...?widget.initial?.selectedOptions};
    _selectedAddOns = {...?widget.initial?.selectedAddOns};
  }

  // ── Computed ────────────────────────────────────────────────────────────

  double get _total {
    double t = widget.item.basePrice;
    for (final o in _selectedOptions.values) {
      t += o.priceDelta;
    }
    for (final entry in _selectedAddOns.entries) {
      final option = _findOption(entry.key);
      if (option != null) t += option.priceDelta * entry.value;
    }
    return t;
  }

  /// First required group with no selection. Drives disabled-CTA hint.
  OptionGroup? get _firstUnfilledRequired {
    for (final g in widget.item.optionGroups) {
      if (!g.required) continue;
      if (g.type == OptionGroupType.singleSelect &&
          !_selectedOptions.containsKey(g.id)) {
        return g;
      }
      if (g.type == OptionGroupType.multiAddOn) {
        final any = g.options.any(
          (o) => (_selectedAddOns['${g.id}:${o.id}'] ?? 0) > 0,
        );
        if (!any) return g;
      }
    }
    return null;
  }

  Option? _findOption(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    for (final g in widget.item.optionGroups) {
      if (g.id != parts[0]) continue;
      for (final o in g.options) {
        if (o.id == parts[1]) return o;
      }
    }
    return null;
  }

  // ── Mutators ────────────────────────────────────────────────────────────

  void _selectOption(OptionGroup group, Option option) {
    setState(() => _selectedOptions[group.id] = option);
  }

  void _setAddOnQty(OptionGroup group, Option option, int qty) {
    final key = '${group.id}:${option.id}';
    setState(() {
      if (qty <= 0) {
        _selectedAddOns.remove(key);
      } else {
        _selectedAddOns[key] = qty.clamp(0, 99);
      }
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      CatalogCustomizationResult(
        quantity: 1,
        selectedOptions: Map.unmodifiable(_selectedOptions),
        selectedAddOns: Map.unmodifiable(_selectedAddOns),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final unfilled = _firstUnfilledRequired;
    final canSubmit = unfilled == null;
    final ctaLabel = canSubmit
        ? s.catalogAddToOrderCta
        : s.catalogPickRequiredHint(unfilled.name.toLowerCase());

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Column(
            children: [
              const _Handle(),
              _Header(
                item: widget.item,
                onBack: () => Navigator.of(context).pop(),
                onClose: () => Navigator.of(context).pop(),
              ),
              Divider(height: 1, color: ColorPalette.opsBorder),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    if (widget.item.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          widget.item.description,
                          style: TypographyManager.bodyMedium.copyWith(
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                      ),
                    for (final g in widget.item.optionGroups) ...[
                      _GroupHeader(group: g),
                      const SizedBox(height: 8),
                      if (g.type == OptionGroupType.singleSelect)
                        for (final o in g.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RadioRow(
                              option: o,
                              selected: _selectedOptions[g.id]?.id == o.id,
                              onTap: () => _selectOption(g, o),
                            ),
                          )
                      else
                        for (final o in g.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AddOnRow(
                              option: o,
                              quantity:
                                  _selectedAddOns['${g.id}:${o.id}'] ?? 0,
                              onMinus: () => _setAddOnQty(
                                g,
                                o,
                                (_selectedAddOns['${g.id}:${o.id}'] ?? 0) - 1,
                              ),
                              onPlus: () => _setAddOnQty(
                                g,
                                o,
                                (_selectedAddOns['${g.id}:${o.id}'] ?? 0) + 1,
                              ),
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: ColorPalette.opsBorder),
              _TotalRow(
                label: s.catalogItemTotalLabel,
                amount: formatMoney(_total),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: ElevatedButton(
                  onPressed: canSubmit ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.opsPurple,
                    foregroundColor: ColorPalette.white,
                    disabledBackgroundColor: ColorPalette.opsSurfaceSubtle,
                    disabledForegroundColor: ColorPalette.textSecondary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: TypographyManager.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(ctaLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: ColorPalette.opsBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CatalogItem item;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _Header({
    required this.item,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back_rounded, onPressed: onBack),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: TypographyManager.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Base: ${formatMoney(item.basePrice)}',
                  style: TypographyManager.bodySmall.copyWith(
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _CircleIcon(icon: Icons.close_rounded, onPressed: onClose),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleIcon({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.opsSurfaceSubtle,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: ColorPalette.textPrimary),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final OptionGroup group;
  const _GroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            group.name,
            style: TypographyManager.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: group.required
                ? ColorPalette.error.withValues(alpha: 0.12)
                : ColorPalette.opsSurfaceSubtle,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            group.required ? s.catalogTagRequired : s.catalogTagOptional,
            style: TypographyManager.bodySmall.copyWith(
              color: group.required
                  ? ColorPalette.error
                  : ColorPalette.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioRow extends StatelessWidget {
  final Option option;
  final bool selected;
  final VoidCallback onTap;

  const _RadioRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Material(
      color: selected
          ? ColorPalette.itemTileSelectedBg
          : ColorPalette.opsSurface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? ColorPalette.opsPurple
                  : ColorPalette.opsBorder,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _RadioMark(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.name,
                  style: TypographyManager.bodyMedium.copyWith(
                    color: selected
                        ? ColorPalette.opsPurpleDark
                        : ColorPalette.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                option.priceDelta == 0
                    ? s.catalogPriceFree
                    : '+${formatMoney(option.priceDelta)}',
                style: TypographyManager.bodyMedium.copyWith(
                  color: ColorPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  final bool selected;
  const _RadioMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? ColorPalette.opsPurple : ColorPalette.opsBorder,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: ColorPalette.opsPurple,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _AddOnRow extends StatelessWidget {
  final Option option;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _AddOnRow({
    required this.option,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? ColorPalette.itemTileSelectedBg
            : ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? ColorPalette.opsPurple : ColorPalette.opsBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              option.name,
              style: TypographyManager.bodyMedium.copyWith(
                color: selected
                    ? ColorPalette.opsPurpleDark
                    : ColorPalette.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '+${formatMoney(option.priceDelta)}',
            style: TypographyManager.bodySmall.copyWith(
              color: ColorPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          _MiniStepper(
            value: quantity,
            onMinus: onMinus,
            onPlus: onPlus,
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _MiniStepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: ColorPalette.opsSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ColorPalette.opsBorder),
          ),
          child: InkWell(
            onTap: value > 0 ? onMinus : null,
            borderRadius: BorderRadius.circular(6),
            child: Icon(
              Icons.remove_rounded,
              size: 14,
              color: value > 0
                  ? ColorPalette.textPrimary
                  : ColorPalette.textDisabled,
            ),
          ),
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
        Material(
          color: ColorPalette.opsPurple,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPlus,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                Icons.add_rounded,
                size: 14,
                color: ColorPalette.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String amount;
  const _TotalRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TypographyManager.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
            ),
          ),
          Text(
            amount,
            style: TypographyManager.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: ColorPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
