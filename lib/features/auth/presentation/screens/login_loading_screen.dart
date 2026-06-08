import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/app_colors.dart';

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.appColors.loginBgTop,
              context.appColors.loginBgBottom,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: context.appColors.fgOnBrand,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.loading,
                style: TypographyManager.bodyMedium.copyWith(
                  color: context.appColors.loginSubtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
