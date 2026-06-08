import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../shell/presentation/widgets/coming_soon_view.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom-nav slot for Modules. Upstream prototype is unimplemented;
/// we render a styled "Coming soon" placeholder so the tab works.
class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      body: SafeArea(
        child: ComingSoonView(
          icon: Icons.grid_view_outlined,
          description: context.l10n.comingSoonModules,
        ),
      ),
    );
  }
}
