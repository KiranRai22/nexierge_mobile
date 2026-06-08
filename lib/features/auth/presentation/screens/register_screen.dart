import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.appColors.fgOnBrand,
        foregroundColor: context.appColors.fgBase,
        title: Text(
          context.l10n.register,
          style: TypographyManager.titleMedium,
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Register screen — coming soon.'),
        ),
      ),
    );
  }
}
