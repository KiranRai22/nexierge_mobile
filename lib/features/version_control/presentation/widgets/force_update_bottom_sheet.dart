import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_version.dart';

/// Bottom sheet shown for force/mandatory updates.
/// The user CANNOT dismiss this sheet - they must update to continue.
/// Shows only "Update Now" button - no other options.
class ForceUpdateBottomSheet extends StatelessWidget {
  final AppVersion version;
  final String storeUrl;

  const ForceUpdateBottomSheet({
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
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          ForceUpdateBottomSheet(version: version, storeUrl: storeUrl),
    );
  }

  Future<void> _openStore(BuildContext context) async {
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

    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.bgBase,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle (decorative only - can't actually drag)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.bgSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // App icon
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appColors.brandPrimaryTint,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                version.title.isNotEmpty
                    ? version.title
                    : s.updateDialogForceTitle,
                textAlign: TextAlign.center,
                style: TypographyManager.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: c.fgBase,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                version.description.isNotEmpty
                    ? version.description
                    : s.updateDialogForceBody,
                textAlign: TextAlign.center,
                style: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
              ),
              const SizedBox(height: 24),
              // Mandatory update notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appColors.brandPrimaryTint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: context.appColors.brandPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Update required to continue using the app',
                        style: TypographyManager.bodySmall.copyWith(
                          color: context.appColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Update Now button (only option)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.brandPrimary,
                    foregroundColor: context.appColors.fgOnBrand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openStore(context),
                  child: Text(
                    s.updateDialogUpdateNow,
                    style: TypographyManager.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.appColors.fgOnBrand,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
