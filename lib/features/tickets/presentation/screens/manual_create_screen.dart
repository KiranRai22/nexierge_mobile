import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../shell/presentation/widgets/coming_soon_view.dart';

/// Stub screen for the Manual create flow — upstream prototype is 404.
class ManualCreateScreen extends StatelessWidget {
  const ManualCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      appBar: AppBar(
        backgroundColor: ColorPalette.opsSurface,
        foregroundColor: ColorPalette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          s.createManualTitle,
          style: TypographyManager.screenTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ComingSoonView(
          icon: Icons.assignment_outlined,
          description: s.comingSoonManual,
          onPrimaryAction: () => Navigator.of(context).pop(),
          primaryActionLabel: s.backToTickets,
        ),
      ),
    );
  }
}
