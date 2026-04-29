import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_controller.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/profile_language_card.dart';
import '../widgets/profile_logout_button.dart';
import '../widgets/profile_theme_card.dart';

/// Profile tab. Renders the avatar header, account/work info sections, the
/// language preference, and the logout CTA. All data comes from the real
/// `me_user` API via [userProfileControllerProvider], which caches the
/// response in SharedPreferences so the screen loads instantly on warm
/// starts and survives offline sessions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showAvatarComingSoon(BuildContext context) {
    final s = context.l10n;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.profileChangeAvatarComingSoon)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final asyncProfile = ref.watch(userProfileControllerProvider);

    return Container(
      color: c.bgSubtle,
      child: SafeArea(
        bottom: false,
        child: asyncProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
              ),
            ),
          ),
          data: (profile) => _ProfileBody(
            profile: profile,
            onChangeAvatar: () => _showAvatarComingSoon(context),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onChangeAvatar;

  const _ProfileBody({required this.profile, required this.onChangeAvatar});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned avatar block — stays anchored while info sections scroll.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ProfileHeaderCard(
            profile: profile,
            onChangeAvatar: onChangeAvatar,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
            children: [
              // ── Account Information ────────────────────────────────────
              ProfileInfoSection(
                title: s.profileSectionAccountInformation,
                rows: [
                  ProfileInfoRow(
                    label: s.profileFieldName,
                    value: profile.fullName,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldEmail,
                    value: profile.email,
                  ),
                  if (profile.phone != null && profile.phone!.isNotEmpty)
                    ProfileInfoRow(
                      label: s.profileFieldPhone,
                      value: profile.phone!,
                    ),
                  ProfileInfoRow(
                    label: s.profileFieldEmployeeCode,
                    value: profile.employeeCode ?? s.profileFieldEmptyValue,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldRole,
                    value: profile.role,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Work Information ───────────────────────────────────────
              ProfileInfoSection(
                title: s.profileSectionWorkInformation,
                rows: [
                  if (profile.hotelName != null &&
                      profile.hotelName!.isNotEmpty)
                    ProfileInfoRow(
                      label: s.profileFieldHotel,
                      value: profile.hotelName!,
                    ),
                  ProfileInfoRow(
                    label: s.profileFieldDepartments,
                    value: profile.departments.isNotEmpty
                        ? profile.departments.join(', ')
                        : s.profileFieldEmptyValue,
                  ),
                  ProfileInfoRow(
                    label: s.profileFieldStatus,
                    value: _statusLabel(s, profile.status),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Preferences ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Builder(
                  builder: (context) => Text(
                    s.profileSectionPreferences.toUpperCase(),
                    style: TypographyManager.kpiLabel.copyWith(
                      color: context.themeColors.fgSubtle,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const ProfileLanguageCard(),
              const SizedBox(height: 12),
              const ProfileThemeCard(),
              const SizedBox(height: 24),
              const ProfileLogoutButton(),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(AppLocalizations s, UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return s.profileStatusActive;
      case UserStatus.inactive:
        return s.profileStatusInactive;
    }
  }
}
