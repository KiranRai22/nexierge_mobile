import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexierge/core/theme/unified_theme_manager.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/entities/ticket_form_options.dart';
import '../../domain/models/catalog.dart';
import '../providers/catalog_create_controller.dart';
import '../providers/manual_create_controller.dart';
import '../providers/ticket_form_options_provider.dart';
import '../providers/universal_create_controller.dart';
import '../widgets/create/catalog_customizer_sheet.dart';
import '../widgets/create/confirm_ticket_sheet.dart';
import '../widgets/create/department_picker_sheet.dart';
import '../widgets/create/room_picker_sheet.dart';

/// Initial tab shown when opening the create flow.
enum CreateTab { universal, catalog, manual }

/// Unified create screen with three switchable tabs: Universal · Catalog · Manual.
class CreateScreen extends ConsumerStatefulWidget {
  final CreateTab initialTab;
  const CreateScreen({super.key, this.initialTab = CreateTab.universal});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _title(
    BuildContext context,
    UniversalStep universalStep,
    CatalogStep catalogStep,
    Catalog? catalog,
  ) {
    final s = context.l10n;
    switch (_tabs.index) {
      case 0:
        if (universalStep == UniversalStep.fillDetails) {
          return '🔔 ${s.createTicketHeading}';
        }
        return '🔔 ${s.universalHeading}';
      case 1:
        if (catalogStep == CatalogStep.fillDetails) {
          return '🛒 ${s.createTicketHeading}';
        }
        if (catalogStep == CatalogStep.selectItems && catalog != null) {
          return '${catalog.emoji} ${catalog.name}';
        }
        return '🛒 ${s.createCatalogNavTitle}';
      default:
        return '✏️ ${s.createTicketHeading}';
    }
  }

  String? _subtitle(BuildContext context, CatalogDraftState catalogDraft) {
    if (_tabs.index != 1) return null;
    if (catalogDraft.step != CatalogStep.selectItems) return null;
    if (!catalogDraft.hasCart) return null;
    return context.l10n.catalogCartSubtitle(
      catalogDraft.totalUnits,
      formatMoney(catalogDraft.total),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    // Pre-warm rooms+departments fetch on entry so the room picker / dept
    // dropdown have data ready by the time the user reaches them.
    ref.watch(ticketFormOptionsProvider);
    final universalStep = ref.watch(
      universalDraftControllerProvider.select((d) => d.step),
    );
    final catalogDraft = ref.watch(catalogDraftControllerProvider);
    final showCustom =
        _tabs.index == 0 && universalStep == UniversalStep.selectItems;
    final isUniversalDetails =
        _tabs.index == 0 && universalStep == UniversalStep.fillDetails;
    final isCatalogDetails =
        _tabs.index == 1 && catalogDraft.step == CatalogStep.fillDetails;
    final isCatalogItems =
        _tabs.index == 1 && catalogDraft.step == CatalogStep.selectItems;

    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64 + 96),
        child: Material(
          color: ColorPalette.opsSurface,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CreateAppBar(
                  title: _title(
                    context,
                    universalStep,
                    catalogDraft.step,
                    catalogDraft.catalog,
                  ),
                  subtitle: _subtitle(context, catalogDraft),
                  onBack: () {
                    if (isUniversalDetails) {
                      ref
                          .read(universalDraftControllerProvider.notifier)
                          .backToSelection();
                    } else if (isCatalogDetails) {
                      ref
                          .read(catalogDraftControllerProvider.notifier)
                          .backToItems();
                    } else if (isCatalogItems) {
                      ref
                          .read(catalogDraftControllerProvider.notifier)
                          .backToCatalogSelect();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  onClose: () => Navigator.of(context).pop(),
                  onCustom: showCustom ? () => _tabs.animateTo(2) : null,
                  customLabel: s.createCustomButton,
                ),
                Divider(
                  height: .5,
                  thickness: 1,
                  color: ColorPalette.opsBorder,
                ),
                _CreateTabBar(controller: _tabs),
                Divider(height: 1, thickness: 1, color: ColorPalette.opsBorder),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: (isUniversalDetails || isCatalogDetails)
            ? const NeverScrollableScrollPhysics()
            : null,
        children: const [
          _UniversalTabBody(),
          _CatalogTabBody(),
          _ManualTabBody(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _CreateAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback? onCustom;
  final String customLabel;

  const _CreateAppBar({
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.onClose,
    required this.onCustom,
    required this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TypographyManager.screenTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TypographyManager.bodySmall.copyWith(
                        color: ColorPalette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (onCustom != null) ...[
            OutlinedButton(
              onPressed: onCustom,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPalette.textPrimary,
                side: BorderSide(color: ColorPalette.opsBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: TypographyManager.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(customLabel),
            ),
            const SizedBox(width: 8),
          ],
          _CircleIconButton(icon: Icons.close_rounded, onPressed: onClose),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleIconButton({required this.icon, required this.onPressed});

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
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: ColorPalette.textPrimary),
        ),
      ),
    );
  }
}

class _CreateTabBar extends StatelessWidget {
  final TabController controller;
  const _CreateTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final entries = <(int, String, String)>[
      (0, '🔔', s.createUniversalTitle),
      (1, '🛒', s.createCatalogNavTitle),
      (2, '✏️', s.createManualTitle),
    ];
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final activeIndex = controller.index;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                Expanded(
                  child: _SegmentCard(
                    emoji: entries[i].$2,
                    label: entries[i].$3,
                    selected: activeIndex == entries[i].$1,
                    onTap: () => controller.animateTo(entries[i].$1),
                  ),
                ),
                if (i != entries.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SegmentCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ColorPalette.opsPurpleTint
          : ColorPalette.opsSurfaceSubtle,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TypographyManager.labelMedium.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? ColorPalette.opsPurpleDark
                      : ColorPalette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIVERSAL TAB — 2-step wizard
// ─────────────────────────────────────────────────────────────────────────────

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
        // Item list with category sections
        SizedBox.square(dimension: 10),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 0, 16, hasPicks ? 96 : 24),
            children: [
              if (_query.isEmpty) ...[
                for (final cat in UniversalCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CategorySection(
                      label: _categoryLabel(s, cat),
                      items: UniversalCatalog.byCategory(cat),
                      draft: draft,
                      onToggle: ctl.togglePick,
                      onQuantity: ctl.setQuantity,
                    ),
                  ),
              ] else
                _CategorySection(
                  label: '',
                  items: UniversalCatalog.search(_query),
                  draft: draft,
                  onToggle: ctl.togglePick,
                  onQuantity: ctl.setQuantity,
                ),
            ],
          ),
        ),

        // Sticky Continue CTA
        if (hasPicks)
          _StickyContinueCta(count: draft.picks.length, onTap: ctl.goToDetails),
      ],
    );
  }

  String _categoryLabel(AppLocalizations s, UniversalCategory cat) {
    switch (cat) {
      case UniversalCategory.housekeeping:
        return s.categoryHousekeeping;
      case UniversalCategory.fnb:
        return s.categoryFnb;
      case UniversalCategory.frontDesk:
        return s.categoryFrontDesk;
      case UniversalCategory.maintenance:
        return s.categoryMaintenance;
    }
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

String _localizedItemTitle(BuildContext context, UniversalItem item) {
  final s = context.l10n;
  switch (item.id) {
    case 'u_extra_towels':
      return s.itemExtraTowels;
    case 'u_extra_pillows':
      return s.itemExtraPillows;
    case 'u_toiletries_kit':
      return s.itemToiletriesKit;
    case 'u_extra_blanket':
      return s.itemExtraBlanket;
    case 'u_room_cleaning':
      return s.itemRoomCleaning;
    case 'u_water_bottles':
      return s.itemWaterBottles;
    case 'u_ice_bucket':
      return s.itemIceBucket;
    case 'u_concierge_help':
      return s.itemConciergeHelp;
    case 'u_climate_control':
      return s.itemClimateControl;
    case 'u_light_fixture':
      return s.itemLightFixture;
    case 'u_plumbing_issue':
      return s.itemPlumbingIssue;
    default:
      return item.title;
  }
}

String _localizedCategory(BuildContext context, UniversalCategory cat) {
  final s = context.l10n;
  switch (cat) {
    case UniversalCategory.housekeeping:
      return s.categoryHousekeeping;
    case UniversalCategory.fnb:
      return s.categoryFnb;
    case UniversalCategory.frontDesk:
      return s.categoryFrontDesk;
    case UniversalCategory.maintenance:
      return s.categoryMaintenance;
  }
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
                        _localizedCategory(context, item.category),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.createSuccessToast)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(universalDraftControllerProvider);
    final ctl = ref.read(universalDraftControllerProvider.notifier);
    final rooms = ref.watch(apiRoomsProvider);
    final selectedRoom = draft.selectedRoomId == null
        ? null
        : rooms.firstWhere(
            (r) => r.id == draft.selectedRoomId,
            orElse: () => rooms.first,
          );

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
                            final picked = await RoomPickerSheet.show(context);
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
                                    selectedRoom != null
                                        ? s.roomNumber(selectedRoom.number)
                                        : s.roomPickerTitle,
                                    style: TypographyManager.bodyMedium
                                        .copyWith(
                                          color: selectedRoom != null
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

// ─────────────────────────────────────────────────────────────────────────────
// CATALOG TAB — 3-step flow (selector → menu → details)
// ─────────────────────────────────────────────────────────────────────────────

/// Helper used by catalog flow to render prices like "$14.50".
String formatMoney(double v) {
  if (v == 0) return r'$0.00';
  return '\$${v.toStringAsFixed(2)}';
}

class _CatalogTabBody extends ConsumerWidget {
  const _CatalogTabBody();

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
        CatalogStep.selectItems => const _CatalogStepItems(
          key: ValueKey('cat-items'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final catalogs = ref.watch(catalogsProvider);
    final ctl = ref.read(catalogDraftControllerProvider.notifier);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          s.createCatalogSelectHeading,
          style: TypographyManager.textHeading.copyWith(
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.createCatalogSelectSubheading,
          style: TypographyManager.bodyMedium.copyWith(
            color: ColorPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        for (final c in catalogs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CatalogSelectorCard(
              catalog: c,
              onTap: () => ctl.selectCatalog(c.id),
            ),
          ),
      ],
    );
  }
}

class _CatalogSelectorCard extends StatelessWidget {
  final Catalog catalog;
  final VoidCallback onTap;
  const _CatalogSelectorCard({required this.catalog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Material(
      color: ColorPalette.opsSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: ColorPalette.opsBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColorPalette.opsSurfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ColorPalette.opsBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  catalog.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ColorPalette.opsPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(catalog.name, style: TypographyManager.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catalog.description,
                      style: TypographyManager.cardMeta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.createCatalogItemCount(catalog.items.length),
                      style: TypographyManager.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColorPalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2 — Menu list ────────────────────────────────────────────────────

class _CatalogStepItems extends ConsumerStatefulWidget {
  const _CatalogStepItems({super.key});

  @override
  ConsumerState<_CatalogStepItems> createState() => _CatalogStepItemsState();
}

class _CatalogStepItemsState extends ConsumerState<_CatalogStepItems> {
  final _searchCtl = TextEditingController();
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(catalogDraftControllerProvider);
    final ctl = ref.read(catalogDraftControllerProvider.notifier);
    final catalog = draft.catalog;
    if (catalog == null) {
      return const SizedBox.shrink();
    }

    final items = _filtered(catalog.items);
    final hasCart = draft.hasCart;

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchCtl,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: TypographyManager.bodyMedium,
            decoration: InputDecoration(
              hintText: s.catalogSearchHintNamed(catalog.name),
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

        // Section heading
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              s.catalogAvailableSection,
              style: TypographyManager.sectionOverline,
            ),
          ),
        ),

        // Item list
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 0, 16, hasCart ? 88 : 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              return _CatalogMenuCard(
                item: item,
                draft: draft,
                onAdd: () {
                  if (item.hasOptions) {
                    _onAddOptionedItem(item);
                  } else {
                    ctl.setItemQuantity(item, draft.quantityFor(item.id) + 1);
                  }
                },
                onIncrement: () =>
                    ctl.setItemQuantity(item, draft.quantityFor(item.id) + 1),
                onDecrement: () =>
                    ctl.setItemQuantity(item, draft.quantityFor(item.id) - 1),
                onEditLine: _onEditLine,
                onDeleteLine: (l) => ctl.removeLine(l.id),
              );
            },
          ),
        ),

        // Sticky bottom (info bar + Continue) — full version lands in Phase D.
        if (hasCart) _CatalogStickyContinue(draft: draft, ctl: ctl),
      ],
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
  final void Function(CartLine line) onDeleteLine;

  const _CatalogMenuCard({
    required this.item,
    required this.draft,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEditLine,
    required this.onDeleteLine,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final qty = draft.quantityFor(item.id);
    final lines = draft.linesFor(item.id);
    final selected = qty > 0;
    final priceLabel = item.basePrice == 0
        ? s.catalogPriceFree
        : formatMoney(item.basePrice);
    final showLines = item.hasOptions && lines.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? ColorPalette.itemTileSelectedBg
            : ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? ColorPalette.itemTileSelectedBorder
              : ColorPalette.opsBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ColorPalette.opsSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ColorPalette.opsBorder),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
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
                      item.description,
                      style: TypographyManager.bodySmall.copyWith(
                        color: ColorPalette.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceLabel,
                      style: TypographyManager.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CatalogTrailingControl(
                item: item,
                quantity: qty,
                onAdd: onAdd,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
            ],
          ),
          if (showLines) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < lines.length; i++) ...[
              if (i == 0) Divider(height: 1, color: ColorPalette.opsPurple),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _CartLineRow(
                  index: i + 1,
                  line: lines[i],
                  onEdit: () => onEditLine(lines[i]),
                  onDelete: () => onDeleteLine(lines[i]),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CartLineRow extends StatelessWidget {
  final int index;
  final CartLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CartLineRow({
    required this.index,
    required this.line,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final summary = line.optionsSummary.isEmpty ? '—' : line.optionsSummary;
    return Row(
      children: [
        Expanded(
          child: Text(
            s.catalogLineLabel(index, summary),
            style: TypographyManager.bodyMedium.copyWith(
              color: ColorPalette.opsPurpleDark,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatMoney(line.lineTotal),
          style: TypographyManager.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        _LineActionIcon(
          icon: Icons.edit_outlined,
          color: ColorPalette.opsPurpleDark,
          onTap: onEdit,
        ),
        const SizedBox(width: 4),
        _LineActionIcon(
          icon: Icons.delete_outline_rounded,
          color: ColorPalette.error,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _LineActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _LineActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 18, color: color),
      ),
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
    // With-options + has lines → count badge + circular +
    if (item.hasOptions && quantity > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorPalette.opsPurple,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$quantity',
              style: TypographyManager.bodySmall.copyWith(
                color: ColorPalette.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleAddButton(onTap: onAdd),
        ],
      );
    }
    // Default: just circular +
    return _CircleAddButton(onTap: onAdd);
  }
}

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.opsPurple,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.add_rounded, size: 20, color: ColorPalette.white),
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
        color: ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorPalette.itemTileSelectedBorder),
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
                color: ColorPalette.textPrimary,
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: ColorPalette.opsPurpleDark),
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
      color: ColorPalette.opsPurple,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(9),
        bottomRight: Radius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.add_rounded, size: 16, color: ColorPalette.white),
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
        // Info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: ColorPalette.successTint,
            border: Border(
              top: BorderSide(color: ColorPalette.successBorder, width: 1),
              bottom: BorderSide(color: ColorPalette.successBorder, width: 1),
            ),
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
                    color: ColorPalette.successText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: ctl.clearCart,
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
        ),
        // Continue CTA
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: ctl.goToDetails,
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
    final confirmed = await ConfirmTicketSheet.show(context);
    if (confirmed != true || !mounted) return;
    final id = await ref.read(catalogDraftControllerProvider.notifier).submit();
    if (id == null || !mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.createSuccessToast)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(catalogDraftControllerProvider);
    final ctl = ref.read(catalogDraftControllerProvider.notifier);
    final catalog = draft.catalog;
    if (catalog == null) return const SizedBox.shrink();

    final rooms = ref.watch(apiRoomsProvider);
    final selectedRoom = draft.selectedRoomId == null
        ? null
        : rooms.firstWhere(
            (r) => r.id == draft.selectedRoomId,
            orElse: () => rooms.first,
          );

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
                            final picked = await RoomPickerSheet.show(context);
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
                                    selectedRoom != null
                                        ? s.roomNumber(selectedRoom.number)
                                        : s.roomPickerTitle,
                                    style: TypographyManager.bodyMedium
                                        .copyWith(
                                          color: selectedRoom != null
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
                          decoration: _catalogInput(
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
              _AutoDepartmentField(department: catalog.department),
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
                decoration: _catalogInput(hint: s.createNotesHint),
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

InputDecoration _catalogInput({required String hint, Widget? prefixIcon}) {
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
        color: ColorPalette.opsPurpleTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.opsPurple),
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
                    color: ColorPalette.opsSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColorPalette.opsBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
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
                          color: ColorPalette.opsPurpleDark,
                        ),
                      ),
                      Text(
                        s.catalogCartSubtitle(
                          draft.totalUnits,
                          formatMoney(draft.total),
                        ),
                        style: TypographyManager.bodySmall.copyWith(
                          color: ColorPalette.opsPurpleDark,
                        ),
                      ),
                    ],
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
                          fontWeight: FontWeight.w700,
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
          ),
          Divider(height: 1, color: ColorPalette.opsPurple),
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
            Text(line.item.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColorPalette.opsSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ColorPalette.opsBorder),
              ),
              child: Text(
                'x${line.quantity}',
                style: TypographyManager.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                line.item.name,
                style: TypographyManager.labelMedium.copyWith(
                  color: ColorPalette.opsPurpleDark,
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
                color: ColorPalette.textPrimary,
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
                      color: ColorPalette.opsPurpleDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatMoney(line.lineTotal),
                  style: TypographyManager.bodySmall.copyWith(
                    color: ColorPalette.opsPurpleDark,
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

// ─────────────────────────────────────────────────────────────────────────────
// MANUAL TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ManualTabBody extends ConsumerStatefulWidget {
  const _ManualTabBody();

  @override
  ConsumerState<_ManualTabBody> createState() => _ManualTabBodyState();
}

class _ManualTabBodyState extends ConsumerState<_ManualTabBody> {
  late final TextEditingController _summaryCtl;
  late final TextEditingController _guestCtl;
  late final TextEditingController _notesCtl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(manualDraftControllerProvider);
    _summaryCtl = TextEditingController(text: state.summary);
    _guestCtl = TextEditingController(text: state.guestName);
    _notesCtl = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _summaryCtl.dispose();
    _guestCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = await ref.read(manualDraftControllerProvider.notifier).submit();
    if (id == null || !mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.createSuccessToast)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final draft = ref.watch(manualDraftControllerProvider);
    final ctl = ref.read(manualDraftControllerProvider.notifier);
    final rooms = ref.watch(apiRoomsProvider);
    final selectedRoom = draft.selectedRoomId == null
        ? null
        : rooms.firstWhere(
            (r) => r.id == draft.selectedRoomId,
            orElse: () => rooms.first,
          );

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              // Summary
              _FieldLabel(s.createSummaryLabel, required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _summaryCtl,
                onChanged: ctl.setSummary,
                minLines: 2,
                maxLines: 3,
                style: TypographyManager.bodyMedium,
                decoration: _inputDecoration(hint: s.createSummaryHint),
              ),
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
                            final picked = await RoomPickerSheet.show(context);
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
                                    selectedRoom != null
                                        ? s.roomNumber(selectedRoom.number)
                                        : s.roomPickerTitle,
                                    style: TypographyManager.bodyMedium
                                        .copyWith(
                                          color: selectedRoom != null
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

              // Department picker
              _FieldLabel(s.createDepartmentLabel, required: true),
              const SizedBox(height: 6),
              _DepartmentField(
                value: draft.department,
                onChanged: ctl.setDepartment,
                hint: s.createDepartmentHint,
              ),
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
                onChanged: ctl.setNotes,
                minLines: 3,
                maxLines: 5,
                style: TypographyManager.bodyMedium,
                decoration: _inputDecoration(hint: s.createNotesHint),
              ),
            ],
          ),
        ),

        // Bottom actions
        _ManualBottomBar(draft: draft, onSubmit: _submit),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {required this.required});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TypographyManager.labelMedium.copyWith(
          color: ColorPalette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: ColorPalette.error),
                ),
              ]
            : null,
      ),
    );
  }
}

class _DepartmentField extends ConsumerWidget {
  final HotelDepartment? value;
  final ValueChanged<HotelDepartment> onChanged;
  final String hint;
  const _DepartmentField({
    required this.value,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final asyncOptions = ref.watch(ticketFormOptionsProvider);
    final depts = asyncOptions.maybeWhen(
      data: (o) => o.departments,
      orElse: () => const <HotelDepartment>[],
    );
    final isLoading = asyncOptions.isLoading && depts.isEmpty;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final pickedId = await DepartmentPickerSheet.show(context);
              if (pickedId != null) {
                final picked = depts.firstWhere((d) => d.id == pickedId);
                onChanged(picked);
              }
            },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.bgField,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.borderBase),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value?.name ?? (isLoading ? '${context.l10n.loading} ' : hint),
                style: TypographyManager.bodyMedium.copyWith(
                  color: value != null ? c.fgBase : c.fgSubtle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.chevron_right_rounded, color: c.fgMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SourceChips extends StatelessWidget {
  final TicketSource? selected;
  final ValueChanged<TicketSource> onSelect;
  const _SourceChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final sources = [
      (TicketSource.whatsApp, '💬', s.createSourceWhatsApp),
      (TicketSource.phone, '📞', s.createSourcePhone),
      (TicketSource.frontDesk, '🔔', s.createSourceFrontDesk),
      (TicketSource.walkIn, '🧑', s.createSourceInPerson),
      (TicketSource.system, '⚙️', s.createSourceInternal),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sources.map((entry) {
        final (src, emoji, label) = entry;
        final isSelected = selected == src;
        return GestureDetector(
          onTap: () => onSelect(src),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorPalette.opsPurpleTint
                  : ColorPalette.opsSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? ColorPalette.opsPurple
                    : ColorPalette.opsBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TypographyManager.labelMedium.copyWith(
                    color: isSelected
                        ? ColorPalette.opsPurpleDark
                        : ColorPalette.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ManualBottomBar extends StatelessWidget {
  final ManualDraftState draft;
  final VoidCallback onSubmit;
  const _ManualBottomBar({required this.draft, required this.onSubmit});

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
              onPressed: () => Navigator.of(context).pop(),
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
                disabledBackgroundColor: ColorPalette.opsBorder,
                disabledForegroundColor: ColorPalette.textDisabled,
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
