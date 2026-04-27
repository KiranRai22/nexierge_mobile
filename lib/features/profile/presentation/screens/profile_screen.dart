import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_locale.dart';
import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/i18n/language_picker_sheet.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../shell/presentation/widgets/coming_soon_view.dart';

/// Bottom-nav slot for Profile.
///
/// First-class controls (language, eventually theme + sign-out) live at the
/// top as settings tiles. Anything we haven't built yet falls into the
/// "Coming soon" view below so the tab still feels finished.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final activeLocale =
        ref.watch(localeControllerProvider).valueOrNull ?? AppLocale.system;

    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _SectionHeader(label: s.profileSectionPreferences),
            _SettingsTile(
              icon: Icons.language_outlined,
              label: s.languageTitle,
              trailing: activeLocale.label(s),
              onTap: () => LanguagePickerSheet.show(context),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ComingSoonView(
                icon: Icons.person_outline,
                description: s.comingSoonProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TypographyManager.labelSmall.copyWith(
          color: ColorPalette.textSecondary,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.opsSurface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: ColorPalette.opsDividerSubtle),
              bottom: BorderSide(color: ColorPalette.opsDividerSubtle),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: ColorPalette.opsPurpleSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: ColorPalette.opsPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TypographyManager.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                trailing,
                style: TypographyManager.bodySmall.copyWith(
                  color: ColorPalette.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: ColorPalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
