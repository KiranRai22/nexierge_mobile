import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../providers/session_providers.dart';

/// Tabbed filter sheet: Department | Sort | Type.
class TicketFiltersSheet extends ConsumerStatefulWidget {
  const TicketFiltersSheet._();

  static Future<void> show(BuildContext context) {
    final c = context.themeColors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (_) => const TicketFiltersSheet._(),
    );
  }

  @override
  ConsumerState<TicketFiltersSheet> createState() => _TicketFiltersSheetState();
}

class _TicketFiltersSheetState extends ConsumerState<TicketFiltersSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Set<String> _draftDeptIds;
  late bool _draftNewest;
  late Set<String> _draftTypes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final current = ref.read(resolvedTicketsFilterProvider);
    _draftDeptIds = {...current.departmentIds};
    _draftNewest = current.newestFirst;
    _draftTypes = {...current.ticketTypes};
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _activeCount =>
      _draftDeptIds.length + 1 + _draftTypes.length;

  void _applyFilter() {
    ref.read(ticketsAdvancedFilterProvider.notifier).state = TicketsAdvancedFilter(
      departmentIds: _draftDeptIds,
      newestFirst: _draftNewest,
      ticketTypes: _draftTypes,
    );
    Navigator.of(context).pop();
  }

  void _resetFilter() {
    final depts = ref.read(userAccessDepartmentsProvider);
    setState(() {
      _draftDeptIds = depts.map((d) => d.id).toSet();
      _draftNewest = true;
      _draftTypes = {'universal_request', 'service_catalog'};
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: c.borderBase,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _activeCount > 0
                        ? s.filterTitleWithCount(_activeCount)
                        : s.filterTitle,
                    style: TypographyManager.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.fgBase,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: tapSound(() => Navigator.of(context).pop(), SoundCategory.back),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.bgSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close, size: 20, color: c.fgMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar — same style as ticket detail tabs
          Material(
            color: c.bgBase,
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.borderBase, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2,
                indicatorColor: c.fgBase,
                labelColor: c.fgBase,
                unselectedLabelColor: c.fgMuted,
                labelStyle: TypographyManager.textLabel.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TypographyManager.textLabel,
                tabs: [
                  Tab(text: s.filterTabDepartment, height: 42),
                  Tab(text: s.filterTabSort, height: 42),
                  Tab(text: s.filterTabType, height: 42),
                ],
              ),
            ),
          ),
          // Tab content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DepartmentTab(
                  selectedIds: _draftDeptIds,
                  onToggle: (id, allIds) => setState(() {
                    if (_draftDeptIds.contains(id)) {
                      // Prevent deselecting the last one
                      if (_draftDeptIds.length > 1) _draftDeptIds.remove(id);
                    } else {
                      _draftDeptIds.add(id);
                    }
                  }),
                  onSelectAll: (allIds) =>
                      setState(() => _draftDeptIds = allIds.toSet()),
                ),
                _SortTab(
                  newestFirst: _draftNewest,
                  onChanged: (v) => setState(() => _draftNewest = v),
                ),
                _TypeTab(
                  selectedTypes: _draftTypes,
                  onToggle: (type) => setState(() {
                    if (_draftTypes.contains(type)) {
                      if (_draftTypes.length > 1) _draftTypes.remove(type);
                    } else {
                      _draftTypes.add(type);
                    }
                  }),
                  onSelectAll: () =>
                      setState(() => _draftTypes = {'universal_request', 'service_catalog'}),
                ),
              ],
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: tapSound(_resetFilter, SoundCategory.back),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.fgBase,
                      side: BorderSide(color: c.borderBase),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.filterActionClear,
                      style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: tapSound(_applyFilter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.buttonInverted,
                      foregroundColor: c.fgOnInverted,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.filterActionApply,
                      style: TypographyManager.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.fgOnInverted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Department tab ────────────────────────────────────────────────

class _DepartmentTab extends ConsumerWidget {
  final Set<String> selectedIds;
  final void Function(String id, Set<String> allIds) onToggle;
  final void Function(List<String> allIds) onSelectAll;

  const _DepartmentTab({
    required this.selectedIds,
    required this.onToggle,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final depts = ref.watch(userAccessDepartmentsProvider);
    final allIds = depts.map((d) => d.id).toList();
    final isMulti = depts.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.filterDeptSubtitle,
                  style: TypographyManager.bodySmall.copyWith(color: c.fgSubtle),
                ),
              ),
              if (isMulti) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: tapSound(
                    () => onSelectAll(allIds),
                    SoundCategory.preference,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    s.filterActionSelectAll,
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.tagPurpleIcon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: depts.isEmpty
              ? Center(
                  child: Text(
                    s.emptyState,
                    style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: depts.length,
                  itemBuilder: (ctx, i) {
                    final dept = depts[i];
                    final isOn = selectedIds.contains(dept.id);
                    final isLast = isOn && selectedIds.length == 1;
                    return InkWell(
                      onTap: isLast
                          ? null
                          : tapSound(
                              () => onToggle(dept.id, allIds.toSet()),
                              SoundCategory.preference,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            _Checkbox(
                              isChecked: isOn,
                              isDisabled: isLast,
                              activeColor: c.tagPurpleIcon,
                              inactiveColor: c.borderBase,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dept.name,
                                style: TypographyManager.bodyMedium.copyWith(
                                  color: isLast ? c.fgMuted : c.fgBase,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (dept.isPrimary == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.tagPurpleBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.filterDeptPrimary,
                                  style: TypographyManager.labelSmall.copyWith(
                                    color: c.tagPurpleText,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Sort tab ────────────────────────────────────────────────────

class _SortTab extends StatelessWidget {
  final bool newestFirst;
  final ValueChanged<bool> onChanged;

  const _SortTab({required this.newestFirst, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            s.filterSortSubtitle,
            style: TypographyManager.bodySmall.copyWith(color: c.fgSubtle),
          ),
        ),
        const Divider(height: 1),
        _SortOption(
          label: s.filterSortNewestFirst,
          icon: LucideIcons.arrowDownNarrowWide,
          isSelected: newestFirst,
          onTap: () => onChanged(true),
        ),
        Divider(height: 1, indent: 20, color: c.borderBase),
        _SortOption(
          label: s.filterSortOldestFirst,
          icon: LucideIcons.arrowUpNarrowWide,
          isSelected: !newestFirst,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return InkWell(
      onTap: tapSound(onTap, SoundCategory.preference),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? c.tagPurpleIcon : c.fgMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TypographyManager.bodyMedium.copyWith(
                  color: isSelected ? c.fgBase : c.fgBase,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? c.tagPurpleIcon : c.borderBase,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.tagPurpleIcon,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Type tab ────────────────────────────────────────────────────

class _TypeTab extends StatelessWidget {
  final Set<String> selectedTypes;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;

  const _TypeTab({
    required this.selectedTypes,
    required this.onToggle,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    final options = [
      ('universal_request', s.chipUniversal),
      ('service_catalog', s.chipCatalog),
    ];
    final isMulti = selectedTypes.length < 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.filterTypeSubtitle,
                  style: TypographyManager.bodySmall.copyWith(color: c.fgSubtle),
                ),
              ),
              if (isMulti) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: tapSound(onSelectAll, SoundCategory.preference),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    s.filterActionSelectAll,
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.tagPurpleIcon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        for (final (key, label) in options) ...[
          _TypeOption(
            label: label,
            isChecked: selectedTypes.contains(key),
            isDisabled: selectedTypes.contains(key) && selectedTypes.length == 1,
            onTap: () => onToggle(key),
          ),
          if (key != 'service_catalog') Divider(height: 1, indent: 20, color: c.borderBase),
        ],
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final bool isChecked;
  final bool isDisabled;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.isChecked,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return InkWell(
      onTap: isDisabled ? null : tapSound(onTap, SoundCategory.preference),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            _Checkbox(
              isChecked: isChecked,
              isDisabled: isDisabled,
              activeColor: c.tagPurpleIcon,
              inactiveColor: c.borderBase,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TypographyManager.bodyMedium.copyWith(
                color: isDisabled ? c.fgMuted : c.fgBase,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared checkbox ─────────────────────────────────────────────

class _Checkbox extends StatelessWidget {
  final bool isChecked;
  final bool isDisabled;
  final Color activeColor;
  final Color inactiveColor;

  const _Checkbox({
    required this.isChecked,
    required this.activeColor,
    required this.inactiveColor,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDisabled
        ? (isChecked ? activeColor.withOpacity(0.4) : inactiveColor.withOpacity(0.4))
        : (isChecked ? activeColor : inactiveColor);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 2),
        color: isChecked ? color : Colors.transparent,
      ),
      child: isChecked
          ? Icon(Icons.check, size: 16, color: context.appColors.fgOnBrand)
          : null,
    );
  }
}
