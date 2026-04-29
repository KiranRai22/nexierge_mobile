import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/typography_manager.dart';

/// Settings card with the theme title/subtitle on the left and a 3-state
/// segmented picker on the right (Light · Dark · System). Writes through
/// `themeModeControllerProvider.set(...)` which persists the choice; the
/// root `MaterialApp` watches the same provider so the change is visible
/// instantly and survives a cold start.
class ProfileThemeCard extends ConsumerWidget {
  const ProfileThemeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final c = context.themeColors;
    final mode =
        ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;

    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBase),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.profileThemeTitle,
            style: TypographyManager.bodyMedium.copyWith(
              color: c.fgBase,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.profileThemeSubtitle,
            style: TypographyManager.bodySmall.copyWith(color: c.fgSubtle),
          ),
          const SizedBox(height: 12),
          _ThemeSegmented(
            selected: mode,
            onChanged: (next) =>
                ref.read(themeModeControllerProvider.notifier).set(next),
          ),
        ],
      ),
    );
  }
}

class _ThemeSegmented extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeSegmented({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.tagNeutralBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _Chip(
            icon: LucideIcons.sun,
            label: s.profileThemeLight,
            isSelected: selected == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _Chip(
            icon: LucideIcons.moon,
            label: s.profileThemeDark,
            isSelected: selected == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
          _Chip(
            icon: LucideIcons.monitor,
            label: s.profileThemeSystem,
            isSelected: selected == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Chip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Expanded(
      child: Material(
        // Brand purple selected state — intentionally NOT theme-aware.
        color: isSelected ? ColorPalette.opsPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : c.fgSubtle,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TypographyManager.labelSmall.copyWith(
                    color: isSelected ? Colors.white : c.fgSubtle,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
