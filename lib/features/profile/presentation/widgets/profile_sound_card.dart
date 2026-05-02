import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/sound_preferences_provider.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Sound toggle card in profile preferences section
class ProfileSoundCard extends ConsumerWidget {
  const ProfileSoundCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final soundEnabled = ref.watch(soundPreferencesProvider);

    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBase),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sound',
                  style: TypographyManager.bodyMedium.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable or disable app sound effects and notifications',
                  style: TypographyManager.bodySmall.copyWith(color: c.fgSubtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SoundToggle(
            soundEnabled: soundEnabled,
            onChanged: (value) async {
              // Play preference sound before toggling
              await SoundManager.instance.play(SoundCategory.preference);

              // Toggle sound preference
              await ref.read(soundPreferencesProvider.notifier).toggle();

              // Update SoundManager state
              SoundManager.instance.setEnabled(value);
            },
          ),
        ],
      ),
    );
  }
}

class _SoundToggle extends StatelessWidget {
  final bool soundEnabled;
  final ValueChanged<bool> onChanged;

  const _SoundToggle({
    required this.soundEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.tagNeutralBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'ON',
            isSelected: soundEnabled,
            onTap: () => onChanged(true),
          ),
          _ToggleChip(
            label: 'OFF',
            isSelected: !soundEnabled,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Material(
      color: isSelected ? ColorPalette.opsPurple : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TypographyManager.labelLarge.copyWith(
              color: isSelected ? Colors.white : c.fgSubtle,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
