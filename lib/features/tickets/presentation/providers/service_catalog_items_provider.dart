import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ticket_remote_data_source.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/catalog.dart';

/// Maps a single API [ServiceCatalogItemDto] to the domain [CatalogItem]
/// the UI / cart layers already understand.
///
/// `image` URLs from the API are stored as the `emoji` field is reserved for
/// the small emoji glyph; for now we map a single placeholder emoji and let
/// the UI use `images` separately if needed.
CatalogItem _mapItemDtoToCatalogItem(ServiceCatalogItemDto dto) {
  final groups = <OptionGroup>[];
  for (final m in dto.modifierList) {
    final g = m.modifierGroup;
    if (g == null) continue;

    // Single-select when max_select == 1, otherwise multi-add-on.
    final type = g.maxSelect <= 1
        ? OptionGroupType.singleSelect
        : OptionGroupType.multiAddOn;

    groups.add(
      OptionGroup(
        id: g.id,
        name: g.name,
        type: type,
        required: g.isRequired,
        options: g.modifiers
            .map(
              (mod) => Option(
                id: mod.id,
                name: mod.name,
                priceDelta: mod.price,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  // Pick a sensible emoji glyph — the UI shows an image instead when present
  // (handled by the menu card), so this is just a fallback for cards/lines
  // that don't render a network image.
  const fallbackEmoji = '🍽️';

  return CatalogItem(
    id: dto.id,
    name: dto.name,
    description: dto.description ?? '',
    emoji: fallbackEmoji,
    basePrice: dto.price,
    optionGroups: groups,
    imageUrl: dto.images.isNotEmpty ? dto.images.first : null,
  );
}

/// Async provider that fetches all items for a given catalog id.
final serviceCatalogItemsProvider =
    FutureProvider.family.autoDispose<List<CatalogItem>, String>((
      ref,
      catalogId,
    ) async {
      if (catalogId.isEmpty) return const [];
      debugPrint('[serviceCatalogItemsProvider] fetching for $catalogId');
      final repo = ref.read(ticketRepositoryProvider);
      final dtos = await repo.fetchServiceCatalogItems(catalogId: catalogId);
      debugPrint(
        '[serviceCatalogItemsProvider] fetched ${dtos.length} items',
      );
      return dtos.map(_mapItemDtoToCatalogItem).toList(growable: false);
    });
