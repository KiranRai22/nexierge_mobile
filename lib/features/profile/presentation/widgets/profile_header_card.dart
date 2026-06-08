import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../domain/entities/user_profile.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserProfile profile;
  final bool uploadingAvatar;
  final bool updatingName;
  final VoidCallback? onChangeAvatar;
  final VoidCallback? onEditName;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    this.uploadingAvatar = false,
    this.updatingName = false,
    this.onChangeAvatar,
    this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      decoration: CardDecoration.raised(
        colors: c,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          _Avatar(
            initials: profile.initials,
            avatarUrl: profile.avatarUrl,
            uploading: uploadingAvatar,
            onChange: onChangeAvatar,
          ),
          const SizedBox(height: 16),
          // Full name + pencil edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.fullName,
                  textAlign: TextAlign.center,
                  style: TypographyManager.headlineSmall.copyWith(
                    color: c.fgBase,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Pencil icon — mirrors the camera badge style
              updatingName
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : GestureDetector(
                      onTap: tapSound(onEditName),
                      child: Tooltip(
                        message: context.l10n.profileEditNameTitle,
                        child: Icon(
                          LucideIcons.pencil,
                          size: 16,
                          color: c.fgSubtle,
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 8),
          _RolePill(label: profile.role),
          if (profile.departments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile.departments.join(' · '),
              textAlign: TextAlign.center,
              style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onChange;

  const _Avatar({
    required this.initials,
    this.avatarUrl,
    this.uploading = false,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar circle
          ClipOval(
            child: uploading
                ? const ShimmerCircle(size: 128)
                : avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    width: 128,
                    height: 128,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _InitialsDisc(initials: initials),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      // Shimmer skeleton in place of a spinner — gives the
                      // avatar slot a stable filled appearance while the
                      // network image streams in.
                      return const ShimmerCircle(size: 128);
                    },
                  )
                : _InitialsDisc(initials: initials),
          ),
          // Camera badge — hidden while uploading
          if (!uploading)
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
                  onTap: tapSound(onChange),
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

class _InitialsDisc extends StatelessWidget {
  final String initials;
  const _InitialsDisc({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      color: context.appColors.brandPrimary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TypographyManager.headlineMedium.copyWith(
          color: context.appColors.fgOnBrand,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Role pill ─────────────────────────────────────────────────────────────────

class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.brandPrimaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.labelSmall.copyWith(
          color: context.appColors.brandPrimaryHover,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
