import 'package:flutter/foundation.dart';

import 'department.dart';

/// A hotel service catalog (e.g. Hotel Restaurant, Room Service).
@immutable
class Catalog {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Department department;
  final List<CatalogItem> items;

  const Catalog({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.department,
    required this.items,
  });
}

/// One item on a catalog menu.
@immutable
class CatalogItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final double basePrice;
  final List<OptionGroup> optionGroups;

  /// Optional remote image (set when the item is sourced from the API).
  /// When present, the menu card shows this instead of the emoji tile.
  final String? imageUrl;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.basePrice,
    this.optionGroups = const [],
    this.imageUrl,
  });

  bool get hasOptions => optionGroups.isNotEmpty;
}

/// A group of options. Either single-select (radio) or multi-select stepper
/// add-ons depending on [type].
enum OptionGroupType { singleSelect, multiAddOn }

@immutable
class OptionGroup {
  final String id;
  final String name;
  final OptionGroupType type;
  final bool required;
  final List<Option> options;

  const OptionGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    required this.options,
  });
}

@immutable
class Option {
  final String id;
  final String name;
  final double priceDelta;

  const Option({required this.id, required this.name, this.priceDelta = 0.0});
}

/// One configured line in the cart. Each `Add to Order` press appends a
/// CartLine — the same item with different options is a separate line.
@immutable
class CartLine {
  /// Stable line id (uuid-ish from controller).
  final String id;

  /// Catalog item this line is built from.
  final CatalogItem item;

  /// Quantity (only > 1 for items WITHOUT options; option-bearing items
  /// always have 1 unit per configured line).
  final int quantity;

  /// Selected single-select options keyed by group id.
  final Map<String, Option> selectedOptions;

  /// Selected multi-add-ons with quantity, keyed by `${groupId}:${optionId}`.
  final Map<String, int> selectedAddOns;

  const CartLine({
    required this.id,
    required this.item,
    this.quantity = 1,
    this.selectedOptions = const {},
    this.selectedAddOns = const {},
  });

  /// Sum of base price + selected option deltas + add-ons (× quantity).
  double get unitPrice {
    double extras = 0;
    for (final opt in selectedOptions.values) {
      extras += opt.priceDelta;
    }
    for (final entry in selectedAddOns.entries) {
      final option = _findAddOn(entry.key);
      if (option != null) extras += option.priceDelta * entry.value;
    }
    return item.basePrice + extras;
  }

  double get lineTotal => unitPrice * quantity;

  /// Human-readable summary of selections, e.g. "Yes, Agege Bread".
  String get optionsSummary {
    final parts = <String>[];
    for (final opt in selectedOptions.values) {
      parts.add(opt.name);
    }
    for (final entry in selectedAddOns.entries) {
      final option = _findAddOn(entry.key);
      if (option == null) continue;
      parts.add(
        entry.value > 1 ? '${option.name} ×${entry.value}' : option.name,
      );
    }
    return parts.join(', ');
  }

  Option? _findAddOn(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    for (final g in item.optionGroups) {
      if (g.id != parts[0]) continue;
      for (final o in g.options) {
        if (o.id == parts[1]) return o;
      }
    }
    return null;
  }

  CartLine copyWith({
    int? quantity,
    Map<String, Option>? selectedOptions,
    Map<String, int>? selectedAddOns,
  }) {
    return CartLine(
      id: id,
      item: item,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
    );
  }
}
