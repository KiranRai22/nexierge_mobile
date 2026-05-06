import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/app_locale.dart';
import '../../../../core/i18n/l10n_extension.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/providers/sound_preferences_provider.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';

/// Preferences section with expand/collapse.
/// Groups Language, Theme, Sound. Shows summary when collapsed.
class ProfilePreferencesSection extends ConsumerStatefulWidget {
  const ProfilePreferencesSection({super.key});

  @override
  ConsumerState<ProfilePreferencesSection> createState() =>
      _ProfilePreferencesSectionState();
}

class _ProfilePreferencesSectionState
    extends ConsumerState<ProfilePreferencesSection> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with expand/collapse
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.profileSectionPreferences.toUpperCase(),
                  style: TypographyManager.kpiLabel.copyWith(
                    color: c.fgSubtle,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: c.fgSubtle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Summary card when collapsed
        if (!_isExpanded)
          _buildSummaryCard()
        else
          // Expanded content - individual cards
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                _buildLanguageCard(),
                const SizedBox(height: 12),
                _buildThemeCard(),
                const SizedBox(height: 12),
                _buildSoundCard(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final s = context.l10n;
    final c = context.themeColors;

    final locale =
        ref.watch(localeControllerProvider).valueOrNull ?? AppLocale.system;
    final themeMode =
        ref.watch(themeModeControllerProvider).valueOrNull ?? ThemeMode.system;
    final soundEnabled = ref.watch(soundPreferencesProvider);

    final languageCode = _resolveLanguageCode(locale);
    final themeLabel = _resolveThemeLabel(s, themeMode);
    final soundLabel = soundEnabled ? 'ON' : 'OFF';

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
            child: Text(
              '${s.profileLanguageTitle}: $languageCode, ${s.profileThemeTitle}: $themeLabel, Sound: $soundLabel',
              style: TypographyManager.bodyMedium.copyWith(color: c.fgBase),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveLanguageCode(AppLocale locale) {
    if (locale == AppLocale.spanish) return 'ES';
    if (locale == AppLocale.english) return 'EN';
    final code = Localizations.localeOf(context).languageCode;
    return code == 'es' ? 'ES' : 'EN';
  }

  String _resolveThemeLabel(AppLocalizations s, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return s.profileThemeLight;
      case ThemeMode.dark:
        return s.profileThemeDark;
      case ThemeMode.system:
        return s.profileThemeSystem;
    }
  }

  // ── Language Card ──────────────────────────────────────────────────────────

  Widget _buildLanguageCard() {
    final s = context.l10n;
    final c = context.themeColors;
    final current =
        ref.watch(localeControllerProvider).valueOrNull ?? AppLocale.system;
    final selected = _resolveLocale(current);
    final languageCode = selected == AppLocale.spanish ? 'ES' : 'EN';

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
                  s.profileLanguageTitle,
                  style: TypographyManager.bodyMedium.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.profileLanguageSubtitle,
                  style: TypographyManager.bodySmall.copyWith(
                    color: c.fgSubtle,
                  ),
                ),
              ],
            ),
          ),
          // Toggle on the right
          _buildSegmentedToggle(
            options: ['EN', 'ES'],
            selected: languageCode,
            onChanged: (value) {
              ref
                  .read(localeControllerProvider.notifier)
                  .set(value == 'ES' ? AppLocale.spanish : AppLocale.english);
            },
          ),
        ],
      ),
    );
  }

  AppLocale _resolveLocale(AppLocale current) {
    if (current == AppLocale.english) return AppLocale.english;
    if (current == AppLocale.spanish) return AppLocale.spanish;
    final code = Localizations.localeOf(context).languageCode;
    return code == 'es' ? AppLocale.spanish : AppLocale.english;
  }

  // ── Theme Card ─────────────────────────────────────────────────────────────

  Widget _buildThemeCard() {
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
          _buildThemeSegmented(mode),
        ],
      ),
    );
  }

  Widget _buildThemeSegmented(ThemeMode selected) {
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
          _ThemeChip(
            icon: LucideIcons.sun,
            label: s.profileThemeLight,
            isSelected: selected == ThemeMode.light,
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .set(ThemeMode.light),
          ),
          _ThemeChip(
            icon: LucideIcons.moon,
            label: s.profileThemeDark,
            isSelected: selected == ThemeMode.dark,
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .set(ThemeMode.dark),
          ),
          _ThemeChip(
            icon: LucideIcons.monitor,
            label: s.profileThemeSystem,
            isSelected: selected == ThemeMode.system,
            onTap: () => ref
                .read(themeModeControllerProvider.notifier)
                .set(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  // ── Sound Card ─────────────────────────────────────────────────────────────

  Widget _buildSoundCard() {
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
                  'Enable or disable app sound effects',
                  style: TypographyManager.bodySmall.copyWith(
                    color: c.fgSubtle,
                  ),
                ),
              ],
            ),
          ),
          // Toggle with OFF left, ON right
          _buildSoundToggle(soundEnabled),
        ],
      ),
    );
  }

  Widget _buildSoundToggle(bool soundEnabled) {
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
          // OFF on left
          _ToggleChip(
            label: 'OFF',
            isSelected: !soundEnabled,
            onTap: () async {
              if (soundEnabled) {
                await SoundManager.instance.play(SoundCategory.preference);
                await ref.read(soundPreferencesProvider.notifier).toggle();
                SoundManager.instance.setEnabled(false);
              }
            },
          ),
          // ON on right
          _ToggleChip(
            label: 'ON',
            isSelected: soundEnabled,
            onTap: () async {
              if (!soundEnabled) {
                await SoundManager.instance.play(SoundCategory.preference);
                await ref.read(soundPreferencesProvider.notifier).toggle();
                SoundManager.instance.setEnabled(true);
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Shared Components ────────────────────────────────────────────────────────

  Widget _buildSegmentedToggle({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final c = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.tagNeutralBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Material(
            color: isSelected ? ColorPalette.opsPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => onChanged(opt),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  opt,
                  style: TypographyManager.labelLarge.copyWith(
                    color: isSelected ? Colors.white : c.fgSubtle,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
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
