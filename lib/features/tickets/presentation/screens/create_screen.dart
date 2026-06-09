import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexierge/core/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/service_catalog.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/entities/ticket_form_options.dart';
import '../../domain/models/catalog.dart';
import '../providers/catalog_create_controller.dart';
import '../providers/service_catalog_items_provider.dart';
import '../providers/service_catalogs_provider.dart';
import '../providers/manual_create_controller.dart';
import '../providers/checked_in_guest_stays_provider.dart';
import '../providers/ticket_form_options_provider.dart';
import '../providers/universal_catalog_provider.dart';
import '../providers/universal_create_controller.dart';
import '../widgets/create/catalog_customizer_sheet.dart';
import '../widgets/create/confirm_ticket_sheet.dart';
import '../widgets/create/department_picker_sheet.dart';
import '../widgets/create/room_picker_sheet.dart';
import '../widgets/skeletons/ticket_skeletons.dart';

part 'create_screen_universal.dart';
part 'create_screen_catalog.dart';
part 'create_screen_manual.dart';

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
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2, // Universal and Catalog only (Manual disabled)
      vsync: this,
      initialIndex: widget.initialTab == CreateTab.manual
          ? 0
          : widget.initialTab.index,
    );
    _lastTabIndex = _tabs.index;
    _tabs.addListener(_onTabChanged);
  }

  bool _isSearchVisible = false;

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == _lastTabIndex) return;
    _lastTabIndex = _tabs.index;
    if (mounted) setState(() => _isSearchVisible = false);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
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
      backgroundColor: context.appColors.bgBase,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64 + 96),
        child: Material(
          color: context.appColors.bgBase,
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
                  // onCustom: showCustom ? () => _tabs.animateTo(2) : null,
                  onCustom: null,
                  customLabel: s.createCustomButton,
                  showSearchIcon: showCustom || isCatalogItems,
                  isSearchVisible: _isSearchVisible,
                  onSearchToggle: () =>
                      setState(() => _isSearchVisible = !_isSearchVisible),
                ),
                Divider(
                  height: .5,
                  thickness: 1,
                  color: context.appColors.borderBase,
                ),
                _CreateTabBar(controller: _tabs),
                Divider(height: 1, thickness: 1, color: context.appColors.borderBase),
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
        children: [
          _UniversalTabBody(showSearch: _isSearchVisible),
          _CatalogTabBody(showSearch: _isSearchVisible),
          // _ManualTabBody(), // Manual creation temporarily disabled
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
  final bool showSearchIcon;
  final bool isSearchVisible;
  final VoidCallback onSearchToggle;

  const _CreateAppBar({
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.onClose,
    required this.onCustom,
    required this.customLabel,
    this.showSearchIcon = false,
    this.isSearchVisible = false,
    required this.onSearchToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: onBack,
            soundCategory: SoundCategory.back,
          ),
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
                        color: context.appColors.fgSubtle,
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
                foregroundColor: context.appColors.fgBase,
                side: BorderSide(color: context.appColors.borderBase),
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
          if (showSearchIcon) ...[
            _CircleIconButton(
              icon: isSearchVisible
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
              onPressed: onSearchToggle,
              soundCategory: SoundCategory.preference,
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
  final SoundCategory soundCategory;
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.soundCategory = SoundCategory.button,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.bgSubtle,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onPressed, soundCategory),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: context.appColors.fgBase),
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
      // (2, '✏️', s.createManualTitle), // Manual creation temporarily disabled
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
          ? context.appColors.brandPrimaryTint
          : context.appColors.bgSubtle,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tapSound(onTap, SoundCategory.card),
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
                      ? context.appColors.brandPrimaryHover
                      : context.appColors.fgBase,
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
// Shared filter-chip widgets (accessible from all part files)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          _FilterChipItem(
            label: s.activityTypeAll,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final cat in categories) ...[
            const SizedBox(width: 6),
            _FilterChipItem(
              // Render the localized "Other" label when the internal
              // bucket key is the English literal — the key stays stable
              // for filtering even though the display flips with locale.
              label: cat == 'Other' ? s.categoryOther : cat,
              selected: selected == cat,
              onTap: () => onSelect(cat),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tapSound(onTap, SoundCategory.preference),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.appColors.brandPrimary : context.appColors.bgBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? context.appColors.brandPrimary : context.appColors.borderBase,
          ),
        ),
        child: Text(
          label,
          style: TypographyManager.labelMedium.copyWith(
            color: selected ? context.appColors.fgOnBrand : context.appColors.fgBase,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIVERSAL TAB — 2-step wizard
// ─────────────────────────────────────────────────────────────────────────────
