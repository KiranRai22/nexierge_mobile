import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nexierge/l10n/generated/app_localizations.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/models/department.dart';

/// Department switcher bottom sheet
/// Matches TSX DepartmentSwitcher design with radio-style selection
class DepartmentSwitcher {
  static Future<Department?> show({
    required BuildContext context,
    required List<Department> departments,
    required Department currentDept,
  }) {
    final c = context.themeColors;
    return showModalBottomSheet<Department>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSubtle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DepartmentSwitcherBody(
        departments: departments,
        currentDept: currentDept,
      ),
    );
  }
}

class _DepartmentSwitcherBody extends ConsumerStatefulWidget {
  final List<Department> departments;
  final Department currentDept;

  const _DepartmentSwitcherBody({
    required this.departments,
    required this.currentDept,
  });

  @override
  ConsumerState<_DepartmentSwitcherBody> createState() =>
      _DepartmentSwitcherBodyState();
}

class _DepartmentSwitcherBodyState
    extends ConsumerState<_DepartmentSwitcherBody> {
  late Department _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentDept;
  }

  void _handlePick(Department dept) {
    setState(() => _selected = dept);
    Navigator.of(context).pop(dept);
  }

  String _formatLabel(Department d, AppLocalizations s) {
    return d.label(s);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderBase,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Switch department',
              style: TypographyManager.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: c.fgBase,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              "You're assigned to ${widget.departments.length} departments",
              style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
            ),
            const SizedBox(height: 16),
            // Department list
            ...widget.departments.map((dept) {
              final isSelected = dept == _selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _handlePick(dept),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? c.tagBlueBg : c.bgBase,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? c.tagBlueIcon
                            : c.borderBase.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio circle
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? c.fgOnColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? c.tagBlueIcon
                                  : c.borderStrong,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: c.tagBlueIcon,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Label
                        Text(
                          _formatLabel(dept, s),
                          style: TypographyManager.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.fgBase,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
