import 'package:flutter/material.dart';

import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/app_colors.dart';

/// Raised, centered FAB used in the bottom-nav notch. Triggers the
/// Create-new sheet at any tab.
class CenterFab extends StatelessWidget {
  final VoidCallback onPressed;
  const CenterFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create new ticket',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [context.appColors.brandPrimary, context.appColors.brandPrimaryHover],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.brandPrimary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: tapSound(onPressed),
            child: Icon(Icons.add, size: 26, color: context.appColors.fgOnBrand),
          ),
        ),
      ),
    );
  }
}
