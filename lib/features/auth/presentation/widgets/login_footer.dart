import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Bottom block on the login screen: admin-contact reminder and the
/// app version. Wrapped in SizedBox with 80% width and larger font.
class LoginAdminFooter extends StatelessWidget {
  const LoginAdminFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final width = MediaQuery.of(context).size.width * 0.8;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              s.loginAdminContactFooter,
              textAlign: TextAlign.center,
              style: TypographyManager.bodyMedium.copyWith(
                color: ColorPalette.loginFooterText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.loginAppVersion,
              textAlign: TextAlign.center,
              style: TypographyManager.bodySmall.copyWith(
                color: ColorPalette.loginFooterText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
