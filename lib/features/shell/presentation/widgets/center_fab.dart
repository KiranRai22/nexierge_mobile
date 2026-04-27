import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

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
          gradient: const LinearGradient(
            colors: [ColorPalette.opsPurple, ColorPalette.opsPurpleDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.opsPurple.withValues(0.35),
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
            onTap: onPressed,
            child: const Icon(Icons.add, size: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
