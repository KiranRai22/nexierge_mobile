part of 'create_screen.dart';

class _UniversalTabBody extends ConsumerWidget {
  final bool showSearch;
  const _UniversalTabBody({this.showSearch = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      universalDraftControllerProvider.select((d) => d.step),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: step == UniversalStep.selectItems
          ? _UniversalStepSelect(
              key: const ValueKey('uni-select'),
              showSearch: showSearch,
            )
          : const _UniversalStepDetails(key: ValueKey('uni-details')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — item selection
// ─────────────────────────────────────────────────────────────────────────────

class _UniversalStepSelect extends ConsumerStatefulWidget {
  final bool showSearch;
  const _UniversalStepSelect({super.key, this.showSearch = false});

  @override
  ConsumerState<_UniversalStepSelect> createState() =>
      _UniversalStepSelectState();
}

class _UniversalStepSelectState extends ConsumerState<_UniversalStepSelect> {
  final _searchCtl = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void didUpdateWidget(_UniversalStepSelect oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(universalDraftControllerProvider);
    final ctl = ref.read(universalDraftControllerProvider.notifier);
    final catalogAsync = ref.watch(universalCatalogProvider);

    final hasPicks = draft.picks.isNotEmpty;

    return Column(
      children: [
        // 1. Selection info bar
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: hasPicks
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _SelectionInfoBar(
                      count: draft.picks.length,
                      onClearAll: ctl.clearAllPicks,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // 2. Collapsible search bar
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
                      hintText: s.createSearchHint,
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
                        borderSide: BorderSide(
                          color: context.appColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // 3. Category chips — built inside data callback below; placeholder here
        catalogAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (catalog) {
            if (_query.isNotEmpty) return const SizedBox.shrink();
            final depts = catalog.departments
                .where((d) => d.items.isNotEmpty)
                .toList();
            if (depts.length <= 1) return const SizedBox.shrink();
            final categories = depts.map((d) => d.name).toList();
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
        // 4. Divider
        Divider(height: 1, thickness: 1, color: context.appColors.borderBase),
        // 5. Item list with department sections — dynamic from API.
        const SizedBox(height: 10),
        Expanded(
          child: catalogAsync.when(
            loading: () => const CatalogGridSkeleton(),
            error: (err, _) =>
                _CatalogLoadError(onRetry: () => refreshUniversalCatalog(ref)),
            data: (catalog) => RefreshIndicator(
              onRefresh: () => refreshUniversalCatalog(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16, 0, 16, hasPicks ? 96 : 24),
                children: [
                  if (_query.isNotEmpty) ...[
                    _CategorySection(
                      label: '',
                      items: catalog.search(_query),
                      draft: draft,
                      onToggle: ctl.togglePick,
                      onQuantity: ctl.setQuantity,
                    ),
                  ] else ...[
                    for (final dept in catalog.departments)
                      if (dept.items.isNotEmpty &&
                          (_selectedCategory == null ||
                              _selectedCategory == dept.name))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CategorySection(
                            label: dept.name,
                            items: dept.items,
                            draft: draft,
                            onToggle: ctl.togglePick,
                            onQuantity: ctl.setQuantity,
                          ),
                        ),
                    if (catalog.isEmpty) _CatalogEmpty(),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Sticky Continue CTA
        if (hasPicks)
          _StickyContinueCta(count: draft.picks.length, onTap: ctl.goToDetails),
      ],
    );
  }
}

class _CatalogLoadError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _CatalogLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.universalCatalogLoadError,
              style: TypographyManager.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => onRetry(), child: Text(s.retry)),
          ],
        ),
      ),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: Text(
          s.emptyState,
          style: TypographyManager.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SelectionInfoBar extends StatelessWidget {
  final int count;
  final VoidCallback onClearAll;
  const _SelectionInfoBar({required this.count, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    // Matches the desktop selection banner: deep green-tinted black surface
    // with bright green selection label and a muted "Clear all" link.
    final bg = context.appColors.bgSuccessStrong;
    final accent = context.appColors.fgSuccessOnStrong;
    final muted = context.appColors.fgMutedOnStrong;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bg, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.createSelectionBarSelected(count),
              style: TypographyManager.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
          GestureDetector(
            onTap: tapSound(onClearAll, SoundCategory.back),
            behavior: HitTestBehavior.opaque,
            child: Text(
              s.createSelectionBarClearAll,
              style: TypographyManager.labelMedium.copyWith(
                color: muted,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyContinueCta extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _StickyContinueCta({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: ElevatedButton(
        onPressed: tapSound(onTap, SoundCategory.button),
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
            Text(s.createContinueCta(count)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String label;
  final List<UniversalItem> items;
  final UniversalDraftState draft;
  final void Function(UniversalItem) onToggle;
  final void Function(String, int) onQuantity;

  const _CategorySection({
    required this.label,
    required this.items,
    required this.draft,
    required this.onToggle,
    required this.onQuantity,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label.toUpperCase(), style: TypographyManager.sectionOverline),
          const SizedBox(height: 10),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 158,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            final selected = draft.isPicked(item.id);
            final qty = draft.quantity(item.id).clamp(1, 99);
            return _UniversalItemTile(
              item: item,
              selected: selected,
              quantity: selected ? qty : 1,
              onToggle: () => onToggle(item),
              onQuantityChanged: (q) => onQuantity(item.id, q),
            );
          },
        ),
      ],
    );
  }
}

/// Item titles now arrive locale-resolved from the API (PRESET picks the
/// matching `name_i18n[locale]`; CUSTOM ships only one name). The screen
/// just renders `item.title`.
String _localizedItemTitle(BuildContext context, UniversalItem item) {
  return item.title;
}

class _UniversalItemTile extends StatelessWidget {
  final UniversalItem item;
  final bool selected;
  final int quantity;
  final VoidCallback onToggle;
  final ValueChanged<int> onQuantityChanged;

  const _UniversalItemTile({
    required this.item,
    required this.selected,
    required this.quantity,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  void _openPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: context.appColors.scrimBlack.withValues(alpha: 0.85),
      builder: (_) => _ItemPreviewDialog(
        title: _localizedItemTitle(context, item),
        description: item.description,
        imageUrl: item.imageUrl,
        emoji: item.emoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      label: _localizedItemTitle(context, item),
      child: Material(
        color: context.appColors.tileBg,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tapSound(onToggle, SoundCategory.card),
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Background: image cover, or emoji fallback ─────────
                Positioned.fill(
                  child: _CardCover(imageUrl: item.imageUrl, emoji: item.emoji),
                ),
                // ── Readability gradient (stronger at bottom) ─────────
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromARGB(51, 255, 255, 255),
                          Color.fromARGB(153, 150, 127, 162),
                          Color.fromARGB(238, 111, 75, 112),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // ── Title + description (anchored bottom) ─────────────
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: selected ? 56 : 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localizedItemTitle(context, item),
                        style: TypographyManager.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.appColors.fgOnBrand,
                          shadows: [
                            Shadow(
                              color: context.appColors.scrimBlack.withValues(alpha: 0.8),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Hide the description once the item is picked so the
                      // quantity stepper has room and the card stays clean.
                      if (!selected && item.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: TypographyManager.bodySmall.copyWith(
                            color: context.appColors.fgOnBrand,
                            shadows: [
                              Shadow(
                                color: context.appColors.scrimBlack.withValues(alpha: 0.8),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Top-left preview button ───────────────────────────
                Positioned(
                  top: 6,
                  left: 6,
                  child: _CardIconButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Preview',
                    onTap: () => _openPreview(context),
                  ),
                ),
                // ── Top-right check mark when selected ────────────────
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: context.appColors.brandPrimary,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: context.appColors.scrimBlack.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: context.appColors.fgOnBrand,
                      ),
                    ),
                  ),
                // ── Bottom-center quantity stepper when selected ──────
                if (selected)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Center(
                      child: _QuantityStepper(
                        value: quantity,
                        onChanged: onQuantityChanged,
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

/// Small translucent circular icon button anchored to a card corner.
class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CardIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.scrimBlack.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onTap, SoundCategory.button),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 16, color: context.appColors.fgOnBrand),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed cover for the item tile background. Uses the item's image when
/// available; falls back to a centered emoji on a muted surface so the card
/// still looks intentional when there's no asset.
class _CardCover extends StatelessWidget {
  final String imageUrl;
  final String emoji;

  const _CardCover({required this.imageUrl, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: context.appColors.bgBase,
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 48)),
    );
    if (imageUrl.isEmpty) return fallback;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// Quantity stepper rendered as `(−)  N  (+)`.
///
/// `−` and `+` are square icons sitting inside white circular containers so
/// they read well on top of the card's dark gradient. The number sits
/// between them with a soft shadow for legibility.
class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TypographyManager.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.fgOnBrand,
              shadows: [
                Shadow(
                  color: context.appColors.scrimBlack.withValues(alpha: 0.8),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          onTap: value < 99 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? context.appColors.fgOnBrand
          : context.appColors.fgOnBrand.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? tapSound(onTap!, SoundCategory.button) : null,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? context.appColors.brandPrimaryHover
                : context.appColors.fgDisabled,
          ),
        ),
      ),
    );
  }
}

/// Full-screen image preview with title, description, and close button.
/// Uses Flutter's built-in [InteractiveViewer] so the user can pinch-zoom
/// without pulling in a third-party package.
class _ItemPreviewDialog extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String emoji;

  const _ItemPreviewDialog({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
            child: Container(
              decoration: BoxDecoration(
                color: context.appColors.fgOnBrand,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ColoredBox(
                      color: context.appColors.bgBase,
                      child: imageUrl.isEmpty
                          ? Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 96),
                              ),
                            )
                          : InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 96),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TypographyManager.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.appColors.fgBase,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TypographyManager.bodyMedium.copyWith(
                              color: context.appColors.fgSubtle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _CardIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — details / create ticket
// ─────────────────────────────────────────────────────────────────────────────

class _UniversalStepDetails extends ConsumerStatefulWidget {
  const _UniversalStepDetails({super.key});

  @override
  ConsumerState<_UniversalStepDetails> createState() =>
      _UniversalStepDetailsState();
}

class _UniversalStepDetailsState extends ConsumerState<_UniversalStepDetails> {
  late final TextEditingController _guestCtl;
  late final TextEditingController _notesCtl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(universalDraftControllerProvider);
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
    try {
      final id = await ref
          .read(universalDraftControllerProvider.notifier)
          .submit(
            onRetryMessage: (msg) {
              // Show retry message to user
              if (mounted) {
                context.showInfo(msg);
              }
            },
          );
      if (id == null || !mounted) return;
      context.showSuccess(context.l10n.createSuccessToast);
      // Reset to go back to universal selection screen for next ticket
      // Delay slightly to let toast show and AnimatedSwitcher transition smoothly
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      ref.read(universalDraftControllerProvider.notifier).reset();
    } on UniversalOrderException {
      // Universal order failed after 2 attempts
      // Stay on the current screen and show error toast
      if (mounted) {
        context.showFailure('Ticket creation failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(universalDraftControllerProvider);
    final ctl = ref.read(universalDraftControllerProvider.notifier);
    // Same pattern as the manual form: keep the guest field reactive to the
    // controller so picking a room repopulates the textbox (or clears it
    // when the picked stay has no name on file).
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _UniversalSummaryCard(draft: draft, onEdit: ctl.backToSelection),
              const SizedBox(height: 16),

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
                                    draft.selectedRoomNumber != null
                                        ? s.roomNumber(
                                            draft.selectedRoomNumber!,
                                          )
                                        : s.roomPickerTitle,
                                    style: TypographyManager.bodyMedium
                                        .copyWith(
                                          color:
                                              draft.selectedRoomNumber != null
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
                        if (draft.selectedRoomId != null &&
                            draft.roomId != null)
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: context.appColors.bgSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: context.appColors.borderBase,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      draft.guestName.isNotEmpty
                                          ? draft.guestName
                                          : s.guestPickerTitle,
                                      style: TypographyManager.bodyMedium
                                          .copyWith(
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
                            decoration: _inputDecoration(
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
              _AutoDepartmentField(department: draft.autoDepartment),
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
                decoration: _inputDecoration(hint: s.createNotesHint),
              ),
            ],
          ),
        ),
        _UniversalDetailsBottomBar(
          draft: draft,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: _submit,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon}) {
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
}

class _UniversalSummaryCard extends StatelessWidget {
  final UniversalDraftState draft;
  final VoidCallback onEdit;
  const _UniversalSummaryCard({required this.draft, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final picks = draft.picks.values.toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.brandPrimaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.brandPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.createSummaryCardTitle(picks.length, draft.totalUnits),
                  style: TypographyManager.sectionOverline.copyWith(
                    color: context.appColors.brandPrimaryHover,
                    fontWeight: FontWeight.w700,
                  ),
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
                        fontWeight: FontWeight.w600,
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
          SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: .5,
            color: context.appColors.brandPrimaryHover.withValues(alpha: 0.4),
          ),
          // Room + Guest row
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in picks)
                _SummaryItemChip(
                  emoji: p.item.emoji,
                  title: _localizedItemTitle(context, p.item),
                  quantity: p.quantity,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItemChip extends StatelessWidget {
  final String emoji;
  final String title;
  final int quantity;
  const _SummaryItemChip({
    required this.emoji,
    required this.title,
    required this.quantity,
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
            color: Colors.transparent,
            // borderRadius: BorderRadius.circular(8),
            // border: Border.all(color: context.appColors.borderBase),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
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
            'x$quantity',
            style: TypographyManager.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.fgBase,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TypographyManager.labelMedium.copyWith(
            color: context.appColors.brandPrimaryHover,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AutoDepartmentField extends StatelessWidget {
  final Department department;
  const _AutoDepartmentField({required this.department});

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
              department.label(s),
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

class _UniversalDetailsBottomBar extends StatelessWidget {
  final UniversalDraftState draft;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  const _UniversalDetailsBottomBar({
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
