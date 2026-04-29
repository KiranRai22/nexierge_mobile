import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../data/services/image_picker_service.dart';

/// Modal bottom sheet shown when the user taps the camera affordance on
/// the profile avatar. Lets them either pick from gallery or open the
/// camera. Pure presentation — picking, compression, and upload are
/// handled by the host so the controller stays the single source of
/// truth for profile state.
class ChangeProfilePictureSheet {
  const ChangeProfilePictureSheet._();

  /// Show the sheet and return the user's choice. Returns `null` when
  /// the sheet was dismissed without a selection.
  static Future<ImageSource$?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource$>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SheetBody(),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.borderBase,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.profileAvatarSheetTitle,
                        style: TypographyManager.headlineSmall.copyWith(
                          color: c.fgBase,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.profileAvatarSheetSubtitle,
                        style: TypographyManager.bodyMedium.copyWith(
                          color: c.fgSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, color: c.fgSubtle, size: 20),
                  splashRadius: 20,
                  tooltip: s.cancel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: LucideIcons.upload,
              title: s.profileAvatarSheetUploadTitle,
              subtitle: s.profileAvatarSheetUploadSubtitle,
              onTap: () =>
                  Navigator.of(context).pop(ImageSource$.gallery),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: LucideIcons.camera,
              title: s.profileAvatarSheetCameraTitle,
              subtitle: s.profileAvatarSheetCameraSubtitle,
              onTap: () => Navigator.of(context).pop(ImageSource$.camera),
            ),
            const SizedBox(height: 16),
            _CancelButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Material(
      color: c.bgBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.borderBase),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: c.fgBase),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TypographyManager.bodyLarge.copyWith(
                        color: c.fgBase,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: c.fgSubtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    return Material(
      color: c.bgSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.x, size: 18, color: c.fgBase),
              const SizedBox(width: 8),
              Text(
                s.cancel,
                style: TypographyManager.bodyLarge.copyWith(
                  color: c.fgBase,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
