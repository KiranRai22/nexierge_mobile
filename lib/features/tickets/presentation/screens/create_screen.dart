import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexierge/core/theme/unified_theme_manager.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
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
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _lastTabIndex = _tabs.index;
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == _lastTabIndex) return;
    _lastTabIndex = _tabs.index;
    if (mounted) setState(() {});
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
