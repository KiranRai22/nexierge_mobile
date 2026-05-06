import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

enum CreateChoice { universal, catalog, manual }

/// Bottom sheet shown by the FAB across every tab. Lets the user pick the
/// kind of ticket they want to create. The choice is returned via
/// [Navigator.pop].
class CreateNewSheet extends StatelessWidget {
  const CreateNewSheet({super.key});

  static Future<CreateChoice?> show(BuildContext context) {
    return showModalBottomSheet<CreateChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateNewSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Container(
      decoration: CardDecoration.subtle(
        colors: c,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const _Header(),
            const SizedBox(height: 8),
            _Option(
              choice: CreateChoice.universal,
              icon: Icons.bolt_outlined,
              tint: c.tagBlueBg,
              title: s.createUniversalTitle,
              description: s.createUniversalDesc,
            ),
            _Option(
              choice: CreateChoice.catalog,
              icon: Icons.receipt_long_outlined,
              tint: c.tagGreenBg,
              title: s.createCatalogTitle,
              description: s.createCatalogDesc,
            ),
            _Option(
              choice: CreateChoice.manual,
              icon: Icons.assignment_outlined,
              tint: c.tagOrangeBg,
              title: s.createManualTitle,
              description: s.createManualDesc,
            ),
            const SizedBox(height: 12),
            const _HintFooter(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: c.borderBase,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.createNewTitle,
                  style: TypographyManager.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.fgBase,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.createNewSubtitle,
                  style: TypographyManager.bodyMedium.copyWith(
                    color: c.fgSubtle,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.cancel,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: c.fgMuted),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final CreateChoice choice;
  final IconData icon;
  final Color tint;
  final String title;
  final String description;

  const _Option({
    required this.choice,
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(choice),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: c.borderBase),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: c.fgBase),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TypographyManager.cardTitle.copyWith(
                          color: c.fgBase,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TypographyManager.cardMeta.copyWith(
                          color: c.fgSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox.square(dimension: 10),
                Icon(Icons.more_horiz, color: c.fgMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HintFooter extends StatelessWidget {
  const _HintFooter();
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: c.fgMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.createHint,
              style: TypographyManager.bodySmall.copyWith(color: c.fgMuted),
            ),
          ),
        ],
      ),
    );
  }
}
