import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';

/// Circular brand mark used at the top of the dark login screen.
///
/// Solid dark disc with a thin translucent ring and a centered person
/// glyph rendered in white.
class AuthLogo extends StatelessWidget {
  final double size;

  const AuthLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ColorPalette.loginLogoBg,
        shape: BoxShape.circle,
        border: Border.all(color: ColorPalette.loginLogoBorder, width: 1),
      ),
      child: Icon(
        Icons.person_outline,
        color: ColorPalette.loginLogoIcon,
        size: size * 0.45,
      ),
    );
  }
}
