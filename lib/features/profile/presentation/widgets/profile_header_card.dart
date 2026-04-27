import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/entities/user_profile.dart';

/// Big avatar block at the top of the profile screen — purple disc with
/// initials, camera affordance, full name, role pill, departments meta.
/// Pure presentational; tap on the camera surfaces a "coming soon" toast
/// via [onChangeAvatar] which the host wires up.
class ProfileHeaderCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onChangeAvatar;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    this.onChangeAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderBase),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          _Avatar(initials: profile.initials, onChange: onChangeAvatar),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: TypographyManager.headlineSmall.copyWith(
              color: c.fgBase,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          _RolePill(label: profile.role),
          const SizedBox(height: 12),
          Text(
            profile.departments.join(' · '),
            textAlign: TextAlign.center,
            style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final VoidCallback? onChange;
  const _Avatar({required this.initials, this.onChange});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.appColors;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              // Brand purple — intentionally NOT theme-aware. Brand colour
              // stays consistent across light and dark.
              color: ColorPalette.opsPurple,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TypographyManager.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: c.bgBase,
              shape: CircleBorder(
                side: BorderSide(color: c.borderBase, width: 1),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onChange,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Tooltip(
                    message: s.profileChangeAvatar,
                    child: Icon(
                      LucideIcons.camera,
                      size: 16,
                      color: c.fgSubtle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // Brand purple soft — stays consistent across themes.
        color: ColorPalette.opsPurpleSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          color: ColorPalette.opsPurpleDark,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
