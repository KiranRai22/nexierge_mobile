import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/services/sound_manager.dart';
import '../../../../../core/theme/app_colors.dart';
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
      // Transparent so the image-backed header can paint right to the top
      // edge without a sliver of the sheet's surface colour showing as a
      // white line above the cover image. The body itself wraps content in
      // a clipped, rounded surface.
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Material 3 adds a built-in drag handle in a small reserved strip at
      // the top of the sheet — that strip was showing as a white line above
      // our cover image. Disable it; we render our own handle inside the
      // image-backed header instead.
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
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
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: ColoredBox(
              color: context.appColors.bgBase,
              child: Column(
            children: [
              // Image-backed header: handle + back/close + title/base price +
              // description all sit on top of a full-bleed cover image with a
              // readability gradient. The divider that used to sit directly
              // under the header now lives below this whole block.
              _ImageBackedHeader(
                item: widget.item,
                onBack: () => Navigator.of(context).pop(),
                onClose: () => Navigator.of(context).pop(),
              ),
              Divider(height: 1, color: context.appColors.borderBase),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
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
                              onTap: () {
                                SoundManager.instance.play(
                                  SoundCategory.preference,
                                );
                                _selectOption(g, o);
                              },
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
              Divider(height: 1, color: context.appColors.borderBase),
              _TotalRow(
                label: s.catalogItemTotalLabel,
                amount: formatMoney(_total),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: ElevatedButton(
                  onPressed: canSubmit ? tapSound(_confirm) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.brandPrimary,
                    foregroundColor: context.appColors.fgOnBrand,
                    disabledBackgroundColor: context.appColors.bgSubtle,
                    disabledForegroundColor: context.appColors.fgSubtle,
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
        color: context.appColors.borderBase,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Top section of the sheet, with the item image as a full-bleed background
/// covering the drag handle, the back/close + title row, and the
/// description. A vertical gradient keeps the white text readable. The
/// divider below this block now separates description from the preference
/// groups (it used to sit directly under the header).
class _ImageBackedHeader extends StatelessWidget {
  final CatalogItem item;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _ImageBackedHeader({
    required this.item,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        item.imageUrl != null && item.imageUrl!.isNotEmpty;

    // No-image branch keeps the original inline layout: handle, then a row
    // with back / title / close, then description below.
    if (!hasImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                _CircleIcon(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                ),
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
                          color: context.appColors.fgBase,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Base: ${formatMoney(item.basePrice)}',
                        style: TypographyManager.bodySmall.copyWith(
                          color: context.appColors.fgSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                _CircleIcon(
                  icon: Icons.close_rounded,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          if (item.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                item.description,
                style: TypographyManager.bodyMedium.copyWith(
                  color: context.appColors.fgSubtle,
                ),
              ),
            ),
        ],
      );
    }

    // Image branch: back/close float in the top corners of the cover, while
    // the title/base/description anchor at the bottom over the gradient.
    final bottomBlock = Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            style: TypographyManager.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.fgOnBrand,
              shadows: _textShadows(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Base: ${formatMoney(item.basePrice)}',
            style: TypographyManager.bodySmall.copyWith(
              color: context.appColors.scrimWhite.withValues(alpha: 0.9),
              shadows: _textShadows(context),
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TypographyManager.bodyMedium.copyWith(
                color: context.appColors.scrimWhite.withValues(alpha: 0.95),
                shadows: _textShadows(context),
              ),
            ),
          ],
        ],
      ),
    );

    // Fixed cover height. A Stack whose children are all `Positioned` has
    // nothing to size itself against, so when the parent constraint has
    // unbounded height (which is the case inside the bottom sheet), Stack
    // tries to fill infinity and the layout assertion fires. Anchoring to a
    // concrete height side-steps that and keeps the cover predictable.
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  ColoredBox(color: context.appColors.bgBase),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.appColors.scrimBlack.withValues(alpha: 0.33),
                    context.appColors.scrimBlack.withValues(alpha: 0.53),
                    context.appColors.scrimBlack.withValues(alpha: 0.8),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Title + base price + description, anchored bottom so they sit
          // just above the divider regardless of cover height.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bottomBlock,
          ),
          // Drag handle centered at the very top of the cover.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _Handle()),
          ),
          // Back icon — top-left corner.
          Positioned(
            top: 14,
            left: 12,
            child: _CircleIcon(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              onImage: true,
            ),
          ),
          // Close icon — top-right corner.
          Positioned(
            top: 14,
            right: 12,
            child: _CircleIcon(
              icon: Icons.close_rounded,
              onPressed: onClose,
              onImage: true,
            ),
          ),
        ],
      ),
    );
  }

  static List<Shadow> _textShadows(BuildContext context) => [
        Shadow(
          color: context.appColors.scrimBlack.withValues(alpha: 0.8),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  /// When the icon sits on top of the cover image, switch to a translucent
  /// dark background with a white glyph so it stays legible.
  final bool onImage;

  const _CircleIcon({
    required this.icon,
    required this.onPressed,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onImage
          ? context.appColors.scrimBlack.withValues(alpha: 0.45)
          : context.appColors.bgSubtle,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onPressed, SoundCategory.back),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: onImage ? context.appColors.fgOnBrand : context.appColors.fgBase,
          ),
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
                ? context.appColors.fgError.withValues(alpha: 0.12)
                : context.appColors.bgSubtle,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            group.required ? s.catalogTagRequired : s.catalogTagOptional,
            style: TypographyManager.bodySmall.copyWith(
              color: group.required
                  ? context.appColors.fgError
                  : context.appColors.fgSubtle,
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
          ? context.appColors.brandPrimaryTint
          : context.appColors.bgBase,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? context.appColors.brandPrimary
                  : context.appColors.borderBase,
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
                        ? context.appColors.brandPrimaryHover
                        : context.appColors.fgBase,
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
                  color: context.appColors.fgSubtle,
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
          color: selected ? context.appColors.brandPrimary : context.appColors.borderBase,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: context.appColors.brandPrimary,
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
            ? context.appColors.brandPrimaryTint
            : context.appColors.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? context.appColors.brandPrimary : context.appColors.borderBase,
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
                    ? context.appColors.brandPrimaryHover
                    : context.appColors.fgBase,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '+${formatMoney(option.priceDelta)}',
            style: TypographyManager.bodySmall.copyWith(
              color: context.appColors.fgSubtle,
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
            color: context.appColors.bgBase,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.appColors.borderBase),
          ),
          child: InkWell(
            onTap: value > 0 ? tapSound(onMinus, SoundCategory.button) : null,
            borderRadius: BorderRadius.circular(6),
            child: Icon(
              Icons.remove_rounded,
              size: 14,
              color: value > 0
                  ? context.appColors.fgBase
                  : context.appColors.fgDisabled,
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
          color: context.appColors.brandPrimary,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tapSound(onPlus, SoundCategory.button),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                Icons.add_rounded,
                size: 14,
                color: context.appColors.fgOnBrand,
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
                color: context.appColors.fgSubtle,
              ),
            ),
          ),
          Text(
            amount,
            style: TypographyManager.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.fgBase,
            ),
          ),
        ],
      ),
    );
  }
}
