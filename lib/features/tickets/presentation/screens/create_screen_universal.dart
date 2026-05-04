part of 'create_screen.dart';

class _UniversalTabBody extends ConsumerWidget {
  const _UniversalTabBody();

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
          ? const _UniversalStepSelect(key: ValueKey('uni-select'))
          : const _UniversalStepDetails(key: ValueKey('uni-details')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — item selection
// ─────────────────────────────────────────────────────────────────────────────

class _UniversalStepSelect extends ConsumerStatefulWidget {
  const _UniversalStepSelect({super.key});

  @override
  ConsumerState<_UniversalStepSelect> createState() =>
      _UniversalStepSelectState();
}

class _UniversalStepSelectState extends ConsumerState<_UniversalStepSelect> {
  final _searchCtl = TextEditingController();
  String _query = '';

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
        // Selection info bar (above search per spec)
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: hasPicks
              ? _SelectionInfoBar(
                  count: draft.picks.length,
                  onClearAll: ctl.clearAllPicks,
                )
              : const SizedBox.shrink(),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchCtl,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: TypographyManager.bodyMedium,
            decoration: InputDecoration(
              hintText: s.createSearchHint,
              hintStyle: TypographyManager.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: ColorPalette.textSecondary,
              ),
              filled: true,
              fillColor: ColorPalette.opsSurfaceSubtle,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ColorPalette.opsBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ColorPalette.opsBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ColorPalette.opsPurple),
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: ColorPalette.opsBorder),
        // Item list with department sections — dynamic from API.
        SizedBox.square(dimension: 10),
        Expanded(
          child: catalogAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) => _CatalogLoadError(
              onRetry: () => refreshUniversalCatalog(ref),
            ),
            data: (catalog) => RefreshIndicator(
              onRefresh: () => refreshUniversalCatalog(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding:
                    EdgeInsets.fromLTRB(16, 0, 16, hasPicks ? 96 : 24),
                children: [
                  if (_query.isEmpty) ...[
                    for (final dept in catalog.departments)
                      if (dept.items.isNotEmpty)
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
                  ] else ...[
                    _CategorySection(
                      label: '',
                      items: catalog.search(_query),
                      draft: draft,
                      onToggle: ctl.togglePick,
                      onQuantity: ctl.setQuantity,
                    ),
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
            ElevatedButton(
              onPressed: () => onRetry(),
              child: Text(s.retry),
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ColorPalette.successTint,
        border: Border(
          bottom: BorderSide(color: ColorPalette.successBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.createSelectionBarSelected(count),
              style: TypographyManager.labelMedium.copyWith(
                color: ColorPalette.successText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClearAll,
            behavior: HitTestBehavior.opaque,
            child: Text(
              s.createSelectionBarClearAll,
              style: TypographyManager.labelMedium.copyWith(
                color: ColorPalette.successText,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
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
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.opsPurple,
          foregroundColor: ColorPalette.white,
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: _localizedItemTitle(context, item),
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
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? ColorPalette.itemTileSelectedBorder
                    : ColorPalette.itemTileBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Emoji icon in rounded square
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ColorPalette.opsSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ColorPalette.opsBorder),
                        ),
                        child: Center(
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _localizedItemTitle(context, item),
                        textAlign: TextAlign.center,
                        style: TypographyManager.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? ColorPalette.opsPurpleDark
                              : ColorPalette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.departmentName,
                        textAlign: TextAlign.center,
                        style: TypographyManager.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selected) ...[
                        const SizedBox(height: 8),
                        _QuantityStepper(
                          value: quantity,
                          onChanged: onQuantityChanged,
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: ColorPalette.opsPurple,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: ColorPalette.white,
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

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorPalette.itemTileSelectedBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TypographyManager.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: ColorPalette.opsPurpleDark,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: value < 99 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(
          icon,
          size: 14,
          color: onTap == null
              ? ColorPalette.textDisabled
              : ColorPalette.opsPurpleDark,
        ),
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
    final id = await ref
        .read(universalDraftControllerProvider.notifier)
        .submit();
    if (id == null || !mounted) return;
    Navigator.of(context).pop(true);
    context.showSuccess(context.l10n.createSuccessToast);
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
                            final picked =
                                await RoomPickerSheet.showCheckedIn(context);
                            if (picked != null) ctl.selectRoom(picked);
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: ColorPalette.opsSurfaceSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ColorPalette.opsBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    draft.selectedRoomNumber != null
                                        ? s.roomNumber(
                                            draft.selectedRoomNumber!)
                                        : s.roomPickerTitle,
                                    style: TypographyManager.bodyMedium
                                        .copyWith(
                                          color: draft.selectedRoomNumber !=
                                                  null
                                              ? ColorPalette.textPrimary
                                              : ColorPalette.textSecondary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: ColorPalette.textSecondary,
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
                        TextField(
                          controller: _guestCtl,
                          onChanged: ctl.setGuestName,
                          style: TypographyManager.bodyMedium,
                          decoration: _inputDecoration(
                            hint: s.createGuestHint,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: ColorPalette.textSecondary,
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
        color: ColorPalette.textSecondary,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: ColorPalette.opsSurfaceSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorPalette.opsBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorPalette.opsBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ColorPalette.opsPurple),
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
        color: ColorPalette.opsPurpleTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.opsPurple),
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
                    color: ColorPalette.opsPurpleDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.createSummaryEdit,
                      style: TypographyManager.labelMedium.copyWith(
                        color: ColorPalette.opsPurpleDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: ColorPalette.opsPurpleDark,
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
            color: ColorPalette.opsPurpleDark.withValues(alpha: 0.4),
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
            // border: Border.all(color: ColorPalette.opsBorder),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ColorPalette.opsSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: ColorPalette.opsBorder),
          ),
          child: Text(
            'x$quantity',
            style: TypographyManager.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TypographyManager.labelMedium.copyWith(
            color: ColorPalette.opsPurpleDark,
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
        color: ColorPalette.opsSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorPalette.opsBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              department.label(s),
              style: TypographyManager.bodyMedium.copyWith(
                color: ColorPalette.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ColorPalette.opsPurpleTint,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ColorPalette.opsPurple),
            ),
            child: Text(
              s.createDepartmentAuto,
              style: TypographyManager.bodySmall.copyWith(
                color: ColorPalette.opsPurpleDark,
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
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPalette.textPrimary,
                side: BorderSide(color: ColorPalette.opsBorder),
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
              onPressed: draft.canSubmit ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.opsPurple,
                foregroundColor: ColorPalette.white,
                disabledBackgroundColor: ColorPalette.opsPurple.withValues(
                  alpha: 0.4,
                ),
                disabledForegroundColor: ColorPalette.white.withValues(
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorPalette.white,
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
