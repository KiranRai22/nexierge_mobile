import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/dotted_divider.dart';
import '../../domain/models/department.dart';
import '../providers/session_providers.dart';

/// Modal bottom sheet for choosing departments. Mirrors the prototype's
/// list-of-checkboxes pattern. Apply / Clear at the bottom.
class FilterDepartmentSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.opsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
  late Set<Department> _draft;

  @override
  void initState() {
    super.initState();
    _draft = {...ref.read(departmentFilterProvider)};
  }

  String _subtitle(AppLocalizations s) {
    if (_draft.isEmpty) return s.filterSubtitleAll;
    return s.filterSubtitleSome(_draft.length);
  }

  void _toggle(Department d) {
    setState(() {
      if (_draft.contains(d)) {
        _draft.remove(d);
      } else {
        _draft.add(d);
      }
    });
  }

  void _selectAll() => setState(() => _draft = Department.values.toSet());

  void _clear() => setState(() => _draft = {});

  void _apply() {
    ref.read(departmentFilterProvider.notifier).state = _draft;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            _Header(subtitle: _subtitle(context.l10n)),
            DottedDivider(color: ColorPalette.opsDividerSubtle, thickness: 1, height: 8, dashWidth: 6, gap: 4),
            _DeptList(selected: _draft, onToggle: _toggle),
            DottedDivider(color: ColorPalette.opsDividerSubtle, thickness: 1, height: 8, dashWidth: 6, gap: 4),
            _Footer(onSelectAll: _selectAll, onClear: _clear, onApply: _apply),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: ColorPalette.opsBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String subtitle;
  const _Header({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.filterTitle,
            style: TypographyManager.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TypographyManager.bodySmall),
        ],
      ),
    );
  }
}

class _DeptList extends StatelessWidget {
  final Set<Department> selected;
  final ValueChanged<Department> onToggle;
  const _DeptList({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: Department.values.length,
      itemBuilder: (context, i) {
        final d = Department.values[i];
        final isOn = selected.contains(d);
        return InkWell(
          onTap: () => onToggle(d),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(d.label(s), style: TypographyManager.bodyMedium),
                ),
                Icon(
                  isOn
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: isOn
                      ? ColorPalette.opsPurple
                      : ColorPalette.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onApply;
  const _Footer({
    required this.onSelectAll,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          TextButton(onPressed: onSelectAll, child: Text(s.filterSelectAll)),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: ColorPalette.textSecondary,
            ),
            child: Text(s.filterClear),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.opsPurple,
              foregroundColor: ColorPalette.white,
              minimumSize: const Size(96, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(s.filterApply),
          ),
        ],
      ),
    );
  }
}
