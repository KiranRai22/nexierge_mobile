import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ticket_form_options.dart';
import '../providers/session_providers.dart';
import '../providers/ticket_form_options_provider.dart';
import 'skeletons/ticket_skeletons.dart';

/// Modal bottom sheet for choosing departments. Mirrors the prototype's
/// list-of-checkboxes pattern. Apply / Clear at the bottom.
class FilterDepartmentSheet {
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
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      builder: (_) => const _FilterSheetBody(),
    );
  }
}

class _FilterSheetBody extends ConsumerStatefulWidget {
  const _FilterSheetBody();

  @override
  ConsumerState<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends ConsumerState<_FilterSheetBody> {
  late Set<HotelDepartment> _draft;

  @override
  void initState() {
    super.initState();
    _draft = {...ref.read(departmentFilterProvider)};
  }

  String _subtitle(AppLocalizations s) {
    if (_draft.isEmpty) return s.filterSubtitleAll;
    return s.filterSubtitleSome(_draft.length);
  }

  void _toggle(HotelDepartment dept) {
    setState(() {
      if (_draft.contains(dept)) {
        _draft.remove(dept);
      } else {
        _draft.add(dept);
      }
    });
  }

  void _selectAll(List<HotelDepartment> apiDepts) {
    setState(() => _draft = apiDepts.toSet());
  }

  void _clear() => setState(() => _draft = {});

  void _apply() {
    ref.read(departmentFilterProvider.notifier).state = _draft;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final s = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _Header(
              subtitle: _subtitle(s),
              onClose: () => Navigator.of(context).pop(),
            ),
            // Fixed Select All button below subtitle
            _SelectAllButton(onSelectAll: _selectAll),
            const Divider(height: 1),
            Expanded(
              child: _DeptList(selected: _draft, onToggle: _toggle),
            ),
            _Footer(onClear: _clear, onApply: _apply),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: c.borderBase,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SelectAllButton extends ConsumerWidget {
  final ValueChanged<List<HotelDepartment>> onSelectAll;

  const _SelectAllButton({required this.onSelectAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final asyncDepts = ref.watch(apiDepartmentsAsyncProvider);

    return asyncDepts.when(
      data: (depts) {
        if (depts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: tapSound(
                () => onSelectAll(depts),
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
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Header extends StatelessWidget {
  final String subtitle;
  final VoidCallback onClose;
  const _Header({required this.subtitle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by department',
                  style: TypographyManager.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.fgBase,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TypographyManager.bodySmall.copyWith(
                    color: c.fgSubtle,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: tapSound(onClose, SoundCategory.back),
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
    );
  }
}

class _DeptList extends ConsumerWidget {
  final Set<HotelDepartment> selected;
  final ValueChanged<HotelDepartment> onToggle;

  const _DeptList({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final asyncDepts = ref.watch(apiDepartmentsAsyncProvider);

    return asyncDepts.when(
      data: (depts) {
        // Show every department surfaced by the API; selection key is
        // department_id (carried inside the HotelDepartment).
        if (depts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              s.emptyState,
              style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: false,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: depts.length,
          itemBuilder: (context, i) {
            final dept = depts[i];
            final isOn = selected.contains(dept);

            return InkWell(
              onTap: tapSound(() => onToggle(dept), SoundCategory.preference),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _CustomCheckbox(
                      isChecked: isOn,
                      activeColor: c.tagPurpleIcon,
                      inactiveColor: c.borderBase,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dept.name,
                        style: TypographyManager.bodyMedium.copyWith(
                          color: c.fgBase,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: PickerListSkeleton(showLeadingCircle: false),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            e.toString(),
            style: TypographyManager.bodyMedium.copyWith(color: c.fgError),
          ),
        ),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  final bool isChecked;
  final Color activeColor;
  final Color inactiveColor;

  const _CustomCheckbox({
    required this.isChecked,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isChecked ? activeColor : inactiveColor,
          width: 2,
        ),
        color: isChecked ? activeColor : Colors.transparent,
      ),
      child: isChecked
          ? Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onApply;
  const _Footer({required this.onClear, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: tapSound(onClear, SoundCategory.back),
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
                style: TypographyManager.bodyMedium.copyWith(
                  color: c.fgBase, // Use theme-aware color for dark mode
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: tapSound(onApply),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.filterActionApply,
                style: TypographyManager.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
