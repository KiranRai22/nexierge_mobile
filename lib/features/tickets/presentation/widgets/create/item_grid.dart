import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/universal_create_controller.dart';
import 'item_tile.dart';

/// 2-column grid of [ItemTile]s. State lives in the draft controller so
/// re-orderings or new picks are instantly reflected.
class ItemGrid extends ConsumerWidget {
  const ItemGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(universalDraftControllerProvider);
    final ctl = ref.read(universalDraftControllerProvider.notifier);
    final items = UniversalCatalog.items;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 110,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return ItemTile(
          item: item,
          selected: draft.isPicked(item.id),
          quantity: draft.quantity(item.id) == 0 ? 1 : draft.quantity(item.id),
          onToggle: () => ctl.togglePick(item),
          onQuantityChanged: (q) => ctl.setQuantity(item.id, q),
        );
      },
    );
  }
}
