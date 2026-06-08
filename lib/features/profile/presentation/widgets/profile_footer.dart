import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';

/// Bottom-of-profile branding block: small logo, version stamp, and
/// copyright line. Centered, subdued so it doesn't compete with the Log
/// Out button above it.
class ProfileFooter extends StatelessWidget {
  /// App semver string shown to the user (e.g. `1.0.0`). Pulled from
  /// build config at the call site so this widget stays a pure renderer.
  final String version;

  const ProfileFooter({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final year = DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.bgBase,
              shape: BoxShape.circle,
              border: Border.all(color: c.borderBase),
            ),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nexierge',
            style: TypographyManager.labelMedium.copyWith(
              color: c.fgBase,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.profileFooterVersion(version),
            style: TypographyManager.bodySmall.copyWith(
              color: c.fgMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.profileFooterCopyright(year),
            textAlign: TextAlign.center,
            style: TypographyManager.bodySmall.copyWith(
              color: c.fgMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
