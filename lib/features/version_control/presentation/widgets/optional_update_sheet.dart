import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_version.dart';

/// Bottom sheet shown once per session for optional updates.
/// The user can tap "Update Now" (opens store) or "Remind Me Later" (dismisses).
class OptionalUpdateSheet extends StatelessWidget {
  final AppVersion version;
  final String storeUrl;

  const OptionalUpdateSheet({
    super.key,
    required this.version,
    required this.storeUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required AppVersion version,
    required String storeUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          OptionalUpdateSheet(version: version, storeUrl: storeUrl),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    Navigator.of(context).pop();
    if (storeUrl.isEmpty) return;
    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.appColors.scrimBlack.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.borderBase,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appColors.brandPrimaryTint,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.title.isNotEmpty
                          ? version.title
                          : s.updateDialogOptionalTitle,
                      style: TypographyManager.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.fgBase,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      version.description.isNotEmpty
                          ? version.description
                          : s.updateDialogOptionalBody,
                      style: TypographyManager.bodySmall.copyWith(
                        color: c.fgMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: c.borderBase),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    s.updateDialogRemindLater,
                    style: TypographyManager.labelMedium.copyWith(
                      color: c.fgBase,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.brandPrimary,
                    foregroundColor: context.appColors.fgOnBrand,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openStore(context),
                  child: Text(
                    s.updateDialogUpdateNow,
                    style: TypographyManager.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.appColors.fgOnBrand,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
