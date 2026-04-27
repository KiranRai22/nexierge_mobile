import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../providers/login_controller.dart';

/// Pill-shaped segmented control for choosing the login method (dark).
class LoginModeTabs extends StatelessWidget {
  final LoginMode selected;
  final ValueChanged<LoginMode> onChanged;

  const LoginModeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorPalette.loginTabTrack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.loginTabBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: s.loginTabEmail,
              isSelected: selected == LoginMode.email,
              onTap: () => onChanged(LoginMode.email),
            ),
          ),
          Expanded(
            child: _Segment(
              label: s.loginTabEmployeeCode,
              isSelected: selected == LoginMode.employeeCode,
              onTap: () => onChanged(LoginMode.employeeCode),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.loginTabSelectedBg : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: ColorPalette.loginTabBorder, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TypographyManager.labelLarge.copyWith(
            color: isSelected
                ? ColorPalette.loginTabSelectedFg
                : ColorPalette.loginTabUnselectedFg,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
