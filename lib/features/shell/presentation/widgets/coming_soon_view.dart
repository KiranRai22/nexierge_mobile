import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';

/// Reusable "Coming soon" view used by Modules, Profile, Catalog, Manual
/// stub screens. Keeps the layout consistent across placeholders so the
/// shell never has dead-ends when a tab is tapped.
class ComingSoonView extends StatelessWidget {
  final IconData icon;
  final String description;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  const ComingSoonView({
    super.key,
    required this.icon,
    required this.description,
    this.onPrimaryAction,
    this.primaryActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: ColorPalette.opsPurpleSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: ColorPalette.opsPurple),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.comingSoonTitle,
              style: TypographyManager.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TypographyManager.bodyMedium.copyWith(
                color: ColorPalette.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onPrimaryAction != null && primaryActionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onPrimaryAction,
                style: FilledButton.styleFrom(
                  backgroundColor: ColorPalette.opsPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(primaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
