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
              (mod) =>
                  Option(id: mod.id, name: mod.name, priceDelta: mod.price),
            )
            .toList(growable: false),
      ),
    );
  }

  // Pick a sensible emoji glyph — the UI shows an image instead when present
  // (handled by the menu card), so this is just a fallback for cards/lines
  // that don't render a network image.
  const fallbackEmoji = '🍽️';

  final imageUrl = dto.images.isNotEmpty ? dto.images.first : null;
  debugPrint(
    '[CatalogItem Mapping] Item: ${dto.name}, Images: ${dto.images}, Selected URL: $imageUrl',
  );

  return CatalogItem(
    id: dto.id,
    name: dto.name,
    description: dto.description ?? '',
    emoji: fallbackEmoji,
    basePrice: dto.price,
    optionGroups: groups,
    imageUrl: imageUrl,
    category: dto.categoryName,
  );
}

/// Async provider that fetches all items for a given catalog id.
/// Fetches all pages until no more items are returned.
final serviceCatalogItemsProvider = FutureProvider.family
    .autoDispose<List<CatalogItem>, String>((ref, catalogId) async {
      if (catalogId.isEmpty) return const [];
      debugPrint('[serviceCatalogItemsProvider] fetching all items for $catalogId');
      final repo = ref.read(ticketRepositoryProvider);

      // Fetch all pages until empty
      final allItems = <CatalogItem>[];
      final seenIds = <String>{}; // Track IDs to avoid duplicates
      int page = 0;
      while (true) {
        final dtos = await repo.fetchServiceCatalogItems(catalogId: catalogId, page: page);
        debugPrint('[serviceCatalogItemsProvider] Page $page: fetched ${dtos.length} items');
        if (dtos.isEmpty) break;
        
        // Filter out duplicates and add new items
        for (final dto in dtos) {
          if (!seenIds.contains(dto.id)) {
            seenIds.add(dto.id);
            allItems.add(_mapItemDtoToCatalogItem(dto));
          } else {
            debugPrint('[serviceCatalogItemsProvider] Skipping duplicate item: ${dto.id} - ${dto.name}');
          }
        }
        
        page++;
        // Safety limit - max 10 pages (1000 items at 100 per page)
        if (page > 10) break;
      }

      debugPrint('[serviceCatalogItemsProvider] Total unique items: ${allItems.length} (duplicates skipped: ${seenIds.length - allItems.length})');
      return allItems;
    });
