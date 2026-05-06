import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.55, // Strict 55% max height
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height *
                0.55, // Fixed 55% of screen height
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: c.borderBase,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Switch department',
                          style: TypographyManager.titleMedium.copyWith(
                            color: c.fgBase,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: c.fgMuted,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Department list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: widget.departments.length,
                    itemBuilder: (_, i) {
                      final dept = widget.departments[i];
                      final isSelected = dept == _selected;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: c.bgBase,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _handlePick(dept),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? c.tagBlueIcon
                                      : c.borderBase,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dept.name,
                                      style: TypographyManager.bodyLarge
                                          .copyWith(
                                            color: c.fgBase,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      color: c.tagBlueIcon,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
