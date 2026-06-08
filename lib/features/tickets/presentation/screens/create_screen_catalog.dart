part of 'create_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CATALOG TAB — 3-step flow (selector → menu → details)
// ─────────────────────────────────────────────────────────────────────────────

/// Helper used by catalog flow to render prices like "$14.50".
String formatMoney(double v) {
  if (v == 0) return r'$0.00';
  return '\$${v.toStringAsFixed(2)}';
}

/// Helper class to represent either a category header or an item in the grouped list
class _GroupedListItem {
  final String? category; // Set for headers, null for items
  final CatalogItem? item; // Set for items, null for headers
  final bool isHeader;

  const _GroupedListItem.header(this.category)
      : item = null,
        isHeader = true;

  const _GroupedListItem.item(this.item)
      : category = null,
        isHeader = false;
}

class _CatalogTabBody extends ConsumerWidget {
  final bool showSearch;
  const _CatalogTabBody({this.showSearch = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      catalogDraftControllerProvider.select((d) => d.step),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: switch (step) {
        CatalogStep.selectCatalog => const _CatalogStepSelect(
          key: ValueKey('cat-select'),
        ),
        CatalogStep.selectItems => _CatalogStepItems(
          key: const ValueKey('cat-items'),
          showSearch: showSearch,
        ),
        CatalogStep.fillDetails => const _CatalogStepDetailsPlaceholder(
          key: ValueKey('cat-details'),
        ),
      },
    );
  }
}

// ── Step 1 — Catalog selector ─────────────────────────────────────────────

class _CatalogStepSelect extends ConsumerWidget {
  const _CatalogStepSelect({super.key});

  /// Map an API [ServiceCatalog] (no items embedded) to the in-app
  /// [Catalog] domain model that the rest of the create-flow code uses.
  /// Items are lazy-loaded by the items step via `serviceCatalogItemsProvider`.
  Catalog _toDomainCatalog(ServiceCatalog sc) {
    return Catalog(
      id: sc.id,
      name: sc.name,
      description: sc.description ?? '',
      emoji: '🍽️',
      department: Department.fnb,
      items: const [],
      imageUrl: sc.logoUrl,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final asyncState = ref.watch(serviceCatalogsNotifierProvider);
    final ctl = ref.read(catalogDraftControllerProvider.notifier);

    return asyncState.when(
      loading: () => const _CatalogSelectShimmer(),
      error: (e, _) => _CatalogSelectError(
        error: e.toString(),
        onRetry: () =>
            ref.read(serviceCatalogsNotifierProvider.notifier).refresh(),
      ),
      data: (state) {
        if (state.error != null) {
          return _CatalogSelectError(
            error: state.error!,
            onRetry: () =>
                ref.read(serviceCatalogsNotifierProvider.notifier).refresh(),
          );
        }
        final catalogs = state.catalogs;
        if (catalogs.isEmpty) {
          return _CatalogSelectEmpty(
            onRefresh: () =>
                ref.read(serviceCatalogsNotifierProvider.notifier).refresh(),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(serviceCatalogsNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Text(
                s.createCatalogSelectHeading,
                style: TypographyManager.textHeading.copyWith(
                  color: context.appColors.fgBase,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.createCatalogSelectSubheading,
                style: TypographyManager.bodyMedium.copyWith(
                  color: context.appColors.fgSubtle,
                ),
              ),
              const SizedBox(height: 20),
              for (final sc in catalogs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CatalogSelectorCard(
                    catalog: sc,
                    onTap: () => ctl.selectCatalog(_toDomainCatalog(sc)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogSelectorCard extends StatelessWidget {
  final ServiceCatalog catalog;
  final VoidCallback onTap;
  const _CatalogSelectorCard({required this.catalog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final radius = BorderRadius.circular(14);
    return Material(
      color: context.appColors.bgBase,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onTap, SoundCategory.card),
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.appColors.borderBase),
            borderRadius: radius,
          ),
          child: SizedBox(
            // Fixed card height so the cover image has a concrete size
            // without needing IntrinsicHeight on every row.
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 30% — cover image, edge-to-edge ───────────────────
                Expanded(
                  flex: 3,
                  child: _CatalogCoverImage(logoUrl: catalog.logoUrl),
                ),
                // ── 60% — title + description + item count ────────────
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.appColors.brandPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                catalog.name,
                                style: TypographyManager.cardTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if ((catalog.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            catalog.description!,
                            style: TypographyManager.cardMeta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          s.createCatalogItemCount(catalog.items),
                          style: TypographyManager.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── 10% — chevron ─────────────────────────────────────
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: context.appColors.fgSubtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Edge-to-edge cover image for a catalog card. Falls back to a neutral
/// surface with a plate emoji when the catalog has no logo.
class _CatalogCoverImage extends StatelessWidget {
  final String? logoUrl;
  const _CatalogCoverImage({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = logoUrl != null && logoUrl!.isNotEmpty;
    final fallback = ColoredBox(
      color: context.appColors.bgSubtle,
      child: const Center(
        child: Text('🍽️', style: TextStyle(fontSize: 30)),
      ),
    );
    if (!hasImage) return fallback;
    return Image.network(
      logoUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _CatalogLogoTile extends StatelessWidget {
  final String? logoUrl;
  const _CatalogLogoTile({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.appColors.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.borderBase),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (logoUrl != null && logoUrl!.isNotEmpty)
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Text('🍽️', style: TextStyle(fontSize: 22)),
            )
          : const Text('🍽️', style: TextStyle(fontSize: 22)),
    );
  }
}

// ── Loading / empty / error states ────────────────────────────────────────

class _CatalogSelectShimmer extends StatelessWidget {
  const _CatalogSelectShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.appColors.bgSubtle,
      highlightColor: context.appColors.bgBase,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _shimmerBox(context, width: 200, height: 22),
          const SizedBox(height: 8),
          _shimmerBox(context, width: 280, height: 14),
          const SizedBox(height: 20),
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: context.appColors.bgSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _shimmerBox(BuildContext context, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.bgSubtle,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _CatalogSelectEmpty extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _CatalogSelectEmpty({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: context.appColors.fgSubtle,
          ),
          const SizedBox(height: 16),
          Text(
            'No service catalogs available',
            textAlign: TextAlign.center,
            style: TypographyManager.bodyLarge.copyWith(
              color: context.appColors.fgSubtle,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onRefresh,
              child: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSelectError extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _CatalogSelectError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: [
          Icon(Icons.error_outline, size: 56, color: context.appColors.fgError),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TypographyManager.bodyMedium.copyWith(
              color: context.appColors.fgSubtle,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2 — Menu list ────────────────────────────────────────────────────

class _CatalogStepItems extends ConsumerStatefulWidget {
  final bool showSearch;
  const _CatalogStepItems({super.key, this.showSearch = false});

  @override
  ConsumerState<_CatalogStepItems> createState() => _CatalogStepItemsState();
}

class _CatalogStepItemsState extends ConsumerState<_CatalogStepItems> {
  final _searchCtl = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void didUpdateWidget(_CatalogStepItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showSearch && oldWidget.showSearch) {
      _searchCtl.clear();
      setState(() => _query = '');
    }
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _onAddOptionedItem(CatalogItem item) async {
    final result = await CatalogCustomizerSheet.show(context, item: item);
    if (result == null) return;
    ref
        .read(catalogDraftControllerProvider.notifier)
        .addLine(
          item: item,
          quantity: result.quantity,
          selectedOptions: result.selectedOptions,
          selectedAddOns: result.selectedAddOns,
        );
  }

  Future<void> _onEditLine(CartLine line) async {
    final result = await CatalogCustomizerSheet.show(
      context,
      item: line.item,
      initial: CatalogCustomizationResult(
        quantity: line.quantity,
        selectedOptions: line.selectedOptions,
        selectedAddOns: line.selectedAddOns,
      ),
    );
    if (result == null) return;
    ref
        .read(catalogDraftControllerProvider.notifier)
        .editLine(
          lineId: line.id,
          quantity: result.quantity,
          selectedOptions: result.selectedOptions,
          selectedAddOns: result.selectedAddOns,
        );
  }

  List<CatalogItem> _filtered(List<CatalogItem> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  /// Groups items by category, inserting headers between groups
  List<_GroupedListItem> _groupItemsByCategory(List<CatalogItem> items) {
    // Group by category (null/empty categories go to 'Other')
    final groups = <String, List<CatalogItem>>{};
    for (final item in items) {
      final category = item.category?.isNotEmpty == true ? item.category! : 'Other';
      groups.putIfAbsent(category, () => []);
      groups[category]!.add(item);
    }

    // Sort categories alphabetically
    final sortedCategories = groups.keys.toList()..sort();

    // Build list with headers
    final result = <_GroupedListItem>[];
    for (final category in sortedCategories) {
      // Add header
      result.add(_GroupedListItem.header(category));
      // Add items in this category
      for (final item in groups[category]!) {
        result.add(_GroupedListItem.item(item));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(catalogDraftControllerProvider);
    final ctl = ref.read(catalogDraftControllerProvider.notifier);
    final catalog = draft.catalog;
    if (catalog == null) {
      return const SizedBox.shrink();
    }

    final asyncItems = ref.watch(serviceCatalogItemsProvider(catalog.id));
    final hasCart = draft.hasCart;

    return Column(
      children: [
        // 1. Collapsible search bar
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: widget.showSearch
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: TypographyManager.bodyMedium,
                    decoration: InputDecoration(
                      hintText: s.catalogSearchHintNamed(catalog.name),
                      hintStyle: TypographyManager.bodyMedium.copyWith(
                        color: context.appColors.fgSubtle,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: context.appColors.fgSubtle,
                      ),
                      filled: true,
                      fillColor: context.appColors.bgSubtle,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.appColors.borderBase),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.appColors.borderBase),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: context.appColors.brandPrimary),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // 2. Category chips — built from loaded items
        asyncItems.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (allItems) {
            if (_query.isNotEmpty) return const SizedBox.shrink();
            final categories = allItems
                .map((i) =>
                    i.category?.isNotEmpty == true ? i.category! : 'Other')
                .toSet()
                .toList()
              ..sort();
            if (categories.length <= 1) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 0, 8),
              child: _CategoryChips(
                categories: categories,
                selected: _selectedCategory,
                onSelect: (cat) => setState(() => _selectedCategory = cat),
              ),
            );
          },
        ),

        // 3. Divider
        Divider(height: 1, thickness: 1, color: context.appColors.borderBase),

        // 4. Item list
        Expanded(
          child: asyncItems.when(
            loading: () => const _CatalogItemsShimmer(),
            error: (e, _) => _CatalogItemsError(
              error: e.toString(),
              onRetry: () =>
                  ref.invalidate(serviceCatalogItemsProvider(catalog.id)),
            ),
            data: (allItems) {
              // Apply category filter first (ignored when searching)
              final preFiltered = (_query.isEmpty && _selectedCategory != null)
                  ? allItems
                      .where((i) =>
                          (i.category?.isNotEmpty == true
                              ? i.category!
                              : 'Other') ==
                          _selectedCategory)
                      .toList()
                  : allItems;
              final items = _filtered(preFiltered);
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _query.isEmpty
                          ? s.emptyState
                          : s.emptyState,
                      textAlign: TextAlign.center,
                      style: TypographyManager.bodyMedium.copyWith(
                        color: context.appColors.fgSubtle,
                      ),
                    ),
                  ),
                );
              }
              final groupedItems = _groupItemsByCategory(items);
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(serviceCatalogItemsProvider(catalog.id)),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(16, 0, 16, hasCart ? 88 : 24),
                  itemCount: groupedItems.length,
                  itemBuilder: (_, i) {
                    final groupedItem = groupedItems[i];
                    if (groupedItem.isHeader) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          groupedItem.category ?? 'Other',
                          style: TypographyManager.sectionOverline.copyWith(
                            color: context.appColors.fgSubtle,
                          ),
                        ),
                      );
                    }
                    final item = groupedItem.item!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CatalogMenuCard(
                        item: item,
                        draft: draft,
                        onAdd: () {
                          if (item.hasOptions) {
                            _onAddOptionedItem(item);
                          } else {
                            ctl.setItemQuantity(
                              item,
                              draft.quantityFor(item.id) + 1,
                            );
                          }
                        },
                        onIncrement: () => ctl.setItemQuantity(
                          item,
                          draft.quantityFor(item.id) + 1,
                        ),
                        onDecrement: () => ctl.setItemQuantity(
                          item,
                          draft.quantityFor(item.id) - 1,
                        ),
                        onEditLine: _onEditLine,
                        onIncrementLine: (l) =>
                            ctl.incrementLineQuantity(l.id),
                        onDecrementLine: (l) =>
                            ctl.decrementLineQuantity(l.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        if (hasCart) _CatalogStickyContinue(draft: draft, ctl: ctl),
      ],
    );
  }
}

// ── Items loading / error shims ──────────────────────────────────────────

class _CatalogItemsShimmer extends StatelessWidget {
  const _CatalogItemsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.appColors.bgSubtle,
      highlightColor: context.appColors.bgBase,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 92,
          decoration: BoxDecoration(
            color: context.appColors.bgSubtle,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _CatalogItemsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _CatalogItemsError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.appColors.fgError),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TypographyManager.bodyMedium.copyWith(
                color: context.appColors.fgSubtle,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CatalogMenuCard extends StatelessWidget {
  final CatalogItem item;
  final CatalogDraftState draft;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final void Function(CartLine line) onEditLine;
  final void Function(CartLine line) onIncrementLine;
  final void Function(CartLine line) onDecrementLine;

  const _CatalogMenuCard({
    required this.item,
    required this.draft,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEditLine,
    required this.onIncrementLine,
    required this.onDecrementLine,
  });

  @override
  Widget build(BuildContext context) {
    //debugPrint(
    //   '[CatalogMenuCard] Item: ${item.name}, ImageUrl: ${item.imageUrl}, Emoji: ${item.emoji}',
    // );

    final s = context.l10n;
    final qty = draft.quantityFor(item.id);
    final lines = draft.linesFor(item.id);
    final selected = qty > 0;
    final priceLabel = item.basePrice == 0
        ? s.catalogPriceFree
        : formatMoney(item.basePrice);
    final showLines = item.hasOptions && lines.isNotEmpty;

    final radius = BorderRadius.circular(14);
    // Items with no options use an inline quantity stepper on first add.
    // For those (when at least 1 is in the cart), we drop the third column
    // entirely and tuck the stepper into the price row of the content
    // column. Items with options keep the right-side trailing control so
    // the "+ opens sheet" affordance stays visible.
    final inlineStepper = !item.hasOptions && qty > 0;

    final contentColumn = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            style: TypographyManager.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? context.appColors.brandPrimaryHover
                  : context.appColors.fgBase,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: TypographyManager.bodySmall.copyWith(
              color: context.appColors.fgSubtle,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  priceLabel,
                  style: TypographyManager.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appColors.fgBase,
                  ),
                ),
              ),
              if (inlineStepper)
                _CatalogCircleStepper(
                  value: qty,
                  onMinus: onDecrement,
                  onPlus: onIncrement,
                ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? context.appColors.brandPrimaryTint
            : context.appColors.bgBase,
        borderRadius: radius,
        // Selected state is conveyed by the tint fill alone — the previous
        // bright purple border collided with the in-cart line divider and
        // made the card feel boxed in. Unselected cards keep their neutral
        // hairline so they still register as separate cards.
        border: Border.all(
          color: selected
              ? Colors.transparent
              : context.appColors.borderBase,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Top row: 25% image · 60% content · 15% trailing ─────────
          //    (or 25 / 75 when the stepper is hosted inline in content)
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 25,
                  child: _CatalogItemCover(
                    imageUrl: item.imageUrl,
                    emoji: item.emoji,
                  ),
                ),
                Expanded(
                  flex: inlineStepper ? 75 : 60,
                  child: contentColumn,
                ),
                if (!inlineStepper)
                  Expanded(
                    flex: 15,
                    child: Center(
                      child: _CatalogTrailingControl(
                        item: item,
                        quantity: qty,
                        onAdd: onAdd,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showLines) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  for (int i = 0; i < lines.length; i++) ...[
                    if (i == 0)
                      Divider(height: 1, color: context.appColors.brandPrimary),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: _CartLineRow(
                        index: i + 1,
                        line: lines[i],
                        onEdit: () => onEditLine(lines[i]),
                        onIncrement: () => onIncrementLine(lines[i]),
                        onDecrement: () => onDecrementLine(lines[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Edge-to-edge cover image for a catalog item card. Falls back to the
/// item's emoji on a muted surface when the URL is missing or fails to load.
class _CatalogItemCover extends StatelessWidget {
  final String? imageUrl;
  final String emoji;

  const _CatalogItemCover({required this.imageUrl, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final fallback = ColoredBox(
      color: context.appColors.bgBase,
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
    if (!hasImage) return fallback;
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: context.appColors.bgBase,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.appColors.fgSubtle,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _CartLineRow extends StatelessWidget {
  final int index;
  final CartLine line;
  final VoidCallback onEdit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartLineRow({
    required this.index,
    required this.line,
    required this.onEdit,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final summary = line.optionsSummary.isEmpty ? '—' : line.optionsSummary;
    return Row(
      children: [
        // Tapping the line label re-opens the customizer pre-populated with
        // this line's selections. Previously this was a separate pencil icon
        // alongside a trash icon; both were replaced with the stepper below,
        // so the only path to edit the variant is via the label itself.
        Expanded(
          child: InkWell(
            onTap: tapSound(onEdit, SoundCategory.preference),
            child: Text(
              s.catalogLineLabel(index, summary),
              style: TypographyManager.bodyMedium.copyWith(
                color: context.appColors.brandPrimaryHover,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatMoney(line.lineTotal),
          style: TypographyManager.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: context.appColors.fgBase,
          ),
        ),
        const SizedBox(width: 8),
        // Same stepper widget the no-options inline path uses, so the look
        // and feel matches the seasonal-fruit-plate card. Minus on a line
        // of quantity 1 deletes the line outright (handled by the
        // controller's decrementLineQuantity).
        _CatalogCircleStepper(
          value: line.quantity,
          onMinus: onDecrement,
          onPlus: onIncrement,
        ),
      ],
    );
  }
}

class _CatalogTrailingControl extends StatelessWidget {
  final CatalogItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CatalogTrailingControl({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    // No-options + already in cart → inline stepper
    if (!item.hasOptions && quantity > 0) {
      return _InlineStepper(
        value: quantity,
        onMinus: onDecrement,
        onPlus: onIncrement,
      );
    }
    // With-options: always a single circular `+` button on the trailing
    // edge. Per-variant quantity is controlled via the in-card line rows
    // below, so we don't need to surface a count here. Keeping this
    // trailing slot at a fixed 36 px avoids the right-edge overflow that
    // the previous count-badge + button combo produced inside the 15%
    // trailing column.
    return _CircleAddButton(onTap: onAdd);
  }
}

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.brandPrimary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onTap, SoundCategory.button),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(Icons.add_rounded, size: 20, color: context.appColors.fgOnBrand),
          ),
        ),
      ),
    );
  }
}

class _InlineStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _InlineStepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.bgBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.brandPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperBtn(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TypographyManager.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appColors.fgBase,
              ),
            ),
          ),
          _StepperPlus(onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tapSound(onTap, SoundCategory.button),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: context.appColors.brandPrimaryHover),
      ),
    );
  }
}

class _StepperPlus extends StatelessWidget {
  final VoidCallback onTap;
  const _StepperPlus({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.brandPrimary,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(9),
        bottomRight: Radius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onTap, SoundCategory.button),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.add_rounded, size: 16, color: context.appColors.fgOnBrand),
        ),
      ),
    );
  }
}

/// Inline circular stepper used in catalog menu cards that don't have
/// option groups. Mirrors the universal-card style: standalone circular
/// `−` / `+` icon buttons around the quantity number with no surrounding
/// container, so it tucks cleanly into the bottom-right of the content
/// column instead of stealing a whole right-hand column for itself.
class _CatalogCircleStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CatalogCircleStepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CatalogCircleStepperButton(
          icon: Icons.remove_rounded,
          onTap: onMinus,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TypographyManager.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.fgBase,
            ),
          ),
        ),
        _CatalogCircleStepperButton(
          icon: Icons.add_rounded,
          onTap: onPlus,
        ),
      ],
    );
  }
}

class _CatalogCircleStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CatalogCircleStepperButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.brandPrimary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onTap, SoundCategory.button),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: context.appColors.fgOnBrand),
        ),
      ),
    );
  }
}

class _CatalogStickyContinue extends StatelessWidget {
  final CatalogDraftState draft;
  final CatalogDraftController ctl;
  const _CatalogStickyContinue({required this.draft, required this.ctl});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Info bar — same dark-green pill as the universal selection bar.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.appColors.bgSuccessStrong,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.appColors.bgSuccessStrong, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.catalogCartSubtitle(
                      draft.totalUnits,
                      formatMoney(draft.total),
                    ),
                    style: TypographyManager.labelMedium.copyWith(
                      color: context.appColors.fgSuccessOnStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: tapSound(ctl.clearCart, SoundCategory.back),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    s.createSelectionBarClearAll,
                    style: TypographyManager.labelMedium.copyWith(
                      color: context.appColors.fgMutedOnStrong,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Continue CTA
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: tapSound(ctl.goToDetails),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.brandPrimary,
              foregroundColor: context.appColors.fgOnBrand,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: TypographyManager.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.createContinueCta(draft.totalUnits)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 3 — Create ticket form ───────────────────────────────────────────

class _CatalogStepDetailsPlaceholder extends ConsumerStatefulWidget {
  const _CatalogStepDetailsPlaceholder({super.key});

  @override
  ConsumerState<_CatalogStepDetailsPlaceholder> createState() =>
      _CatalogStepDetailsState();
}

class _CatalogStepDetailsState
    extends ConsumerState<_CatalogStepDetailsPlaceholder> {
  late final TextEditingController _guestCtl;
  late final TextEditingController _notesCtl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(catalogDraftControllerProvider);
    _guestCtl = TextEditingController(text: state.guestName);
    _notesCtl = TextEditingController(text: state.note);
  }

  @override
  void dispose() {
    _guestCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ctl = ref.read(catalogDraftControllerProvider.notifier);
    String? errorMsg;
    final ok = await ConfirmTicketSheet.show(
      context,
      onConfirm: () async {
        try {
          final id = await ctl.submit(
            onRetryMessage: (msg) {
              // Show retry message to user via the sheet's loading state
              // The sheet shows loading spinner, we can add a message overlay if needed
              if (mounted) {
                context.showInfo(msg);
              }
            },
          );
          return id != null;
        } catch (e) {
          errorMsg = e.toString();
          return false;
        }
      },
    );
    if (!mounted || ok == null) return;
    if (ok) {
      context.showSuccess(context.l10n.createSuccessToast);
      ctl.reset();
    } else {
      context.showFailure(errorMsg ?? context.l10n.unknownError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(catalogDraftControllerProvider);
    final ctl = ref.read(catalogDraftControllerProvider.notifier);
    final catalog = draft.catalog;
    if (catalog == null) return const SizedBox.shrink();

    // Keep the read-only guest field synced with the auto-populated name
    // sourced from the picked checked-in stay.
    if (_guestCtl.text != draft.guestName) {
      _guestCtl.value = TextEditingValue(
        text: draft.guestName,
        selection: TextSelection.collapsed(offset: draft.guestName.length),
      );
    }
    // Sync notes field with capitalized state value
    if (_notesCtl.text != draft.note) {
      _notesCtl.value = TextEditingValue(
        text: draft.note,
        selection: TextSelection.collapsed(offset: draft.note.length),
      );
    }

    // selectedRoomId now stores the picked checked-in stay's guest_stay_id.
    // Look up the display row from the checked-in stays provider so we can
    // render the room number; no rooms come from the form-options API now.
    final selectedStay = draft.selectedRoomId == null
        ? null
        : ref.watch(checkedInStayByIdProvider(draft.selectedRoomId!));

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _CatalogSummaryCard(draft: draft, onEdit: ctl.backToItems),
              const SizedBox(height: 16),

              // Room + Guest row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(s.createRoomLabel, required: true),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            SoundManager.instance.play(SoundCategory.button);
                            final picked = await RoomPickerSheet.showCheckedIn(
                              context,
                            );
                            if (picked != null) ctl.selectRoom(picked);
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.appColors.bgSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.appColors.borderBase),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedStay != null
                                        ? s.roomNumber(selectedStay.roomNumber)
                                        : s.roomPickerTitle,
                                    style: TypographyManager.bodyMedium
                                        .copyWith(
                                          color: selectedStay != null
                                              ? context.appColors.fgBase
                                              : context.appColors.fgSubtle,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: context.appColors.fgSubtle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(
                          s.createGuestOptionalLabel,
                          required: false,
                        ),
                        const SizedBox(height: 6),
                        if (draft.selectedRoomId != null && draft.roomId != null)
                          GestureDetector(
                            onTap: () async {
                              SoundManager.instance.play(SoundCategory.button);
                              final picked = await GuestPickerSheet.show(
                                context,
                                roomId: draft.roomId!,
                              );
                              if (picked != null) ctl.selectGuest(picked);
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: context.appColors.bgSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.appColors.borderBase),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      draft.guestName.isNotEmpty
                                          ? draft.guestName
                                          : s.guestPickerTitle,
                                      style: TypographyManager.bodyMedium.copyWith(
                                        color: draft.guestName.isNotEmpty
                                            ? context.appColors.fgBase
                                            : context.appColors.fgSubtle,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: context.appColors.fgSubtle,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          TextField(
                            controller: _guestCtl,
                            onChanged: ctl.setGuestName,
                            style: TypographyManager.bodyMedium,
                            decoration: _catalogInput(
                              context,
                              hint: s.createGuestHint,
                              prefixIcon: Icon(
                                Icons.person_outline,
                                size: 18,
                                color: context.appColors.fgSubtle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Department (read-only with AUTO badge)
              _FieldLabel(s.createDepartmentLabel, required: false),
              const SizedBox(height: 6),
              _CatalogAutoDepartmentField(department: catalog.department),
              const SizedBox(height: 16),

              // Source chips
              _FieldLabel(s.createSourceLabel, required: true),
              const SizedBox(height: 8),
              _SourceChips(selected: draft.source, onSelect: ctl.setSource),
              const SizedBox(height: 16),

              // Notes
              _FieldLabel(s.createNotesOptionalLabel, required: false),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtl,
                onChanged: ctl.setNote,
                minLines: 3,
                maxLines: 5,
                style: TypographyManager.bodyMedium,
                decoration: _catalogInput(context, hint: s.createNotesHint),
              ),
            ],
          ),
        ),
        _CatalogDetailsBottomBar(
          draft: draft,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: _submit,
        ),
      ],
    );
  }
}

InputDecoration _catalogInput(BuildContext context, {required String hint, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TypographyManager.bodyMedium.copyWith(
      color: context.appColors.fgSubtle,
    ),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: context.appColors.bgSubtle,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.appColors.borderBase),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.appColors.borderBase),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.appColors.brandPrimary),
    ),
  );
}

class _CatalogSummaryCard extends StatelessWidget {
  final CatalogDraftState draft;
  final VoidCallback onEdit;
  const _CatalogSummaryCard({required this.draft, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final catalog = draft.catalog!;
    final lines = draft.cart;

    // Build #N indices per item.
    final perItemIndex = <String, int>{};
    final indexed = <(int, CartLine)>[];
    for (final l in lines) {
      final n = (perItemIndex[l.item.id] ?? 0) + 1;
      perItemIndex[l.item.id] = n;
      indexed.add((n, l));
    }

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.brandPrimaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.brandPrimary),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.appColors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.appColors.borderBase),
                  ),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child:
                      (catalog.imageUrl != null && catalog.imageUrl!.isNotEmpty)
                      ? Image.network(
                          catalog.imageUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                color: context.appColors.fgSubtle,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              catalog.emoji,
                              style: const TextStyle(fontSize: 16),
                            );
                          },
                        )
                      : Text(
                          catalog.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        catalog.name,
                        style: TypographyManager.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.appColors.brandPrimaryHover,
                        ),
                      ),
                      Text(
                        s.catalogCartSubtitle(
                          draft.totalUnits,
                          formatMoney(draft.total),
                        ),
                        style: TypographyManager.bodySmall.copyWith(
                          color: context.appColors.brandPrimaryHover,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: tapSound(onEdit, SoundCategory.preference),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.createSummaryEdit,
                        style: TypographyManager.labelMedium.copyWith(
                          color: context.appColors.brandPrimaryHover,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: context.appColors.brandPrimaryHover,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appColors.brandPrimary),
          // Lines
          for (final (idx, line) in indexed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: _CatalogSummaryLine(line: line, lineIndex: idx),
            ),
        ],
      ),
    );
  }
}

class _CatalogSummaryLine extends StatelessWidget {
  final CartLine line;
  final int lineIndex;
  const _CatalogSummaryLine({required this.line, required this.lineIndex});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final hasOptions = line.item.hasOptions;
    final summary = line.optionsSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child:
                    (line.item.imageUrl != null &&
                        line.item.imageUrl!.isNotEmpty)
                    ? Image.network(
                        line.item.imageUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 24,
                            height: 24,
                            color: context.appColors.bgBase,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                color: context.appColors.fgSubtle,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              line.item.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          line.item.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.appColors.bgBase,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.appColors.borderBase),
              ),
              child: Text(
                'x${line.quantity}',
                style: TypographyManager.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appColors.fgBase,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                line.item.name,
                style: TypographyManager.labelMedium.copyWith(
                  color: context.appColors.brandPrimaryHover,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatMoney(line.lineTotal),
              style: TypographyManager.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appColors.fgBase,
              ),
            ),
          ],
        ),
        if (hasOptions && summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.catalogLineLabel(lineIndex, summary),
                    style: TypographyManager.bodySmall.copyWith(
                      color: context.appColors.brandPrimaryHover,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatMoney(line.lineTotal),
                  style: TypographyManager.bodySmall.copyWith(
                    color: context.appColors.brandPrimaryHover,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CatalogDetailsBottomBar extends StatelessWidget {
  final CatalogDraftState draft;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  const _CatalogDetailsBottomBar({
    required this.draft,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: tapSound(onCancel, SoundCategory.back),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appColors.fgBase,
                side: BorderSide(color: context.appColors.borderBase),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TypographyManager.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(s.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: draft.canSubmit ? tapSound(onSubmit) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.brandPrimary,
                foregroundColor: context.appColors.fgOnBrand,
                disabledBackgroundColor: context.appColors.brandPrimary.withValues(
                  alpha: 0.4,
                ),
                disabledForegroundColor: context.appColors.fgOnBrand.withValues(
                  alpha: 0.85,
                ),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TypographyManager.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: draft.submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.appColors.fgOnBrand,
                        ),
                      ),
                    )
                  : Text(s.createTicketCta),
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto department field for catalog tickets that shows "Department Auto Selected"
class _CatalogAutoDepartmentField extends StatelessWidget {
  final Department department;
  const _CatalogAutoDepartmentField({required this.department});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.appColors.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.borderBase),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Department Auto Selected',
              style: TypographyManager.bodyMedium.copyWith(
                color: context.appColors.fgBase,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.appColors.brandPrimaryTint,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.appColors.brandPrimary),
            ),
            child: Text(
              s.createDepartmentAuto,
              style: TypographyManager.bodySmall.copyWith(
                color: context.appColors.brandPrimaryHover,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
