import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexierge/l10n/generated/app_localizations.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';

/// Hero card for ticket detail screen
/// Matches TSX TicketDetailHero with gradient overlay and left color bar
class TicketDetailHero extends StatelessWidget {
  final TicketHeroType type;
  final String title;
  final Widget sourceLine;
  final String statusLabel;

  const TicketDetailHero({
    super.key,
    required this.type,
    required this.title,
    required this.sourceLine,
    required this.statusLabel,
  });

  Color _getBarColor(AppColors c) {
    switch (type) {
      case TicketHeroType.universal:
        return c.tagPurpleIcon;
      case TicketHeroType.paid:
        return c.tagBlueIcon;
      case TicketHeroType.manual:
        return c.fgMuted;
    }
  }

  Color _getGradientColor(AppColors c) {
    switch (type) {
      case TicketHeroType.universal:
        return c.tagPurpleIcon;
      case TicketHeroType.paid:
        return c.tagBlueIcon;
      case TicketHeroType.manual:
        return c.fgMuted;
    }
  }

  String _getTypeLabel(AppLocalizations s) {
    switch (type) {
      case TicketHeroType.universal:
        return s.ticketKindUniversal;
      case TicketHeroType.paid:
        return 'Paid';
      case TicketHeroType.manual:
        return s.ticketKindManual;
    }
  }

  Color _getTypeBg(AppColors c) {
    switch (type) {
      case TicketHeroType.universal:
        return c.tagPurpleBg;
      case TicketHeroType.paid:
        return c.tagBlueBg;
      case TicketHeroType.manual:
        return c.tagNeutralBg;
    }
  }

  Color _getTypeFg(AppColors c) {
    switch (type) {
      case TicketHeroType.universal:
        return c.tagPurpleText;
      case TicketHeroType.paid:
        return c.tagBlueText;
      case TicketHeroType.manual:
        return c.tagNeutralText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderBase),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Gradient overlay at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getGradientColor(c).withOpacity(0.12),
                      _getGradientColor(c).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: _getBarColor(c)),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status pills row
                  Row(
                    children: [
                      // Type pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeBg(c),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getTypeFg(c).withOpacity(0.3)),
                        ),
                        child: Text(
                          _getTypeLabel(s),
                          style: TypographyManager.labelSmall.copyWith(
                            color: _getTypeFg(c),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.tagNeutralBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TypographyManager.labelSmall.copyWith(
                            color: c.tagNeutralText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    title,
                    style: TypographyManager.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: c.fgBase,
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Source line
                  DefaultTextStyle(
                    style: TypographyManager.bodySmall.copyWith(
                      color: c.fgMuted,
                      fontSize: 13,
                    ),
                    child: sourceLine,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TicketHeroType { universal, paid, manual }
