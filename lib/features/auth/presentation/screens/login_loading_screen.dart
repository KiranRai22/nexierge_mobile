import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Brief transition shown after a successful login (spec §7 / §8).
/// Renders the same dark gradient as the login screen so the swap
/// from form → loader is seamless.
class LoginLoadingScreen extends StatelessWidget {
  const LoginLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorPalette.loginBgTop,
              ColorPalette.loginBgBottom,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ColorPalette.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.loading,
                style: TypographyManager.bodyMedium.copyWith(
                  color: ColorPalette.loginSubtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
