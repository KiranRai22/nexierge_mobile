import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

/// Circular brand mark used at the top of the dark login screen.
///
/// App logo inside a light gray circle with padding.
class AuthLogo extends StatelessWidget {
  final double size;

  const AuthLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        shape: BoxShape.circle,
        border: Border.all(color: ColorPalette.loginBgTop, width: 2),
      ),
      child: Image.asset(
        'assets/images/app_logo_with_shadow.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
