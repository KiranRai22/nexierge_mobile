import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../domain/entities/app_version.dart';

/// Full-screen gate shown for force/mandatory updates.
///
/// Wraps [child] and paints over it with a blocking overlay whenever
/// [isForced] is `true`. The user has no way to dismiss this dialog —
/// tapping outside does nothing.
class ForceUpdateGate extends StatelessWidget {
  final bool isForced;
  final AppVersion? version;
  final String storeUrl;
  final Widget child;

  const ForceUpdateGate({
    super.key,
    required this.isForced,
    required this.version,
    required this.storeUrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isForced || version == null) return child;

    return Stack(
      children: [
        child,
        // Absorb all touches below.
        const Positioned.fill(
          child: AbsorbPointer(child: ColoredBox(color: Colors.black54)),
        ),
        Positioned.fill(
          child: Center(
            child: _ForceUpdateDialog(
              version: version!,
              storeUrl: storeUrl,
            ),
          ),
        ),
      ],
    );
  }
}

class _ForceUpdateDialog extends StatelessWidget {
  final AppVersion version;
  final String storeUrl;

  const _ForceUpdateDialog({required this.version, required this.storeUrl});

  Future<void> _openStore() async {
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

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.bgBase,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorPalette.opsPurpleTint,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
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
            Text(
              version.description.isNotEmpty
                  ? version.description
                  : s.updateDialogForceBody,
              textAlign: TextAlign.center,
              style: TypographyManager.bodyMedium.copyWith(color: c.fgMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.opsPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _openStore,
                child: Text(
                  s.updateDialogUpdateNow,
                  style: TypographyManager.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
