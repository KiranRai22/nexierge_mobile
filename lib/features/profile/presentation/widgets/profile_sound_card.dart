import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/sound_preferences_provider.dart';
import '../../../../core/services/sound_manager.dart';
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
        border: Border.all(color: c.borderBase, width: 1),
      ),
      child: InkWell(
        onTap: () async {
          // Play preference sound before toggling
          await SoundManager.instance.play(SoundCategory.preference);

          // Toggle sound preference
          await ref.read(soundPreferencesProvider.notifier).toggle();

          // Update SoundManager state
          SoundManager.instance.setEnabled(soundEnabled);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.tagPurpleBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.volume_up_outlined,
                  color: c.tagPurpleIcon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                      soundEnabled ? 'Enabled' : 'Disabled',
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: soundEnabled,
                onChanged: (value) async {
                  // Play preference sound before toggling
                  await SoundManager.instance.play(SoundCategory.preference);

                  // Toggle sound preference
                  await ref.read(soundPreferencesProvider.notifier).toggle();

                  // Update SoundManager state
                  SoundManager.instance.setEnabled(value);
                },
                activeColor: c.tagPurpleIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
