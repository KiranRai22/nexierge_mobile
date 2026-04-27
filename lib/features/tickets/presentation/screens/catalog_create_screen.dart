import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../shell/presentation/widgets/coming_soon_view.dart';

/// Stub screen for the Catalog create flow — upstream prototype is 404.
/// Wired into the Create-new sheet so routing has no dead-ends.
class CatalogCreateScreen extends StatelessWidget {
  const CatalogCreateScreen({super.key});

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
          s.createCatalogTitle,
          style: TypographyManager.screenTitle,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ComingSoonView(
          icon: Icons.receipt_long_outlined,
          description: s.comingSoonCatalog,
          onPrimaryAction: () => Navigator.of(context).pop(),
          primaryActionLabel: s.backToTickets,
        ),
      ),
    );
  }
}
