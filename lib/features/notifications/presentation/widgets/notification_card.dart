import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/card_theme.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/notification_inbox_item.dart';

/// One inbox row. Mirrors the Lovable prototype:
/// `[+ icon] [title / subtitle] [time + unread dot]`.
///
/// Pure presentation — tap routing and read-state mutations live in the
/// caller (`NotificationsSheet`). Keeps this widget testable in isolation.
class NotificationCard extends StatelessWidget {
  final NotificationInboxItem item;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    final s = context.l10n;
    final radius = BorderRadius.circular(12);

    return Material(
      color: c.bgBase,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: CardDecoration.subtle(colors: c, borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingIcon(c: c),
              const SizedBox(width: 12),
              Expanded(
                child: _Body(item: item, c: c, s: s),
              ),
              const SizedBox(width: 8),
              _Trailing(item: item, c: c, s: s),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final AppColors c;
  const _LeadingIcon({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: c.tagPurpleBg, shape: BoxShape.circle),
      child: Icon(LucideIcons.plus, size: 18, color: c.tagPurpleIcon),
    );
  }
}

class _Body extends StatelessWidget {
  final NotificationInboxItem item;
  final AppColors c;
  final AppLocalizations s;
  const _Body({required this.item, required this.c, required this.s});

  String _resolvedTitle() {
    switch (item.kind) {
      case NotificationInboxKind.newTicket:
        return s.notificationsItemNewTicket;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _resolvedTitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
        ),
        const SizedBox(height: 2),
        Text(
          item.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TypographyManager.textMeta.copyWith(color: c.fgMuted),
        ),
      ],
    );
  }
}

class _Trailing extends StatelessWidget {
  final NotificationInboxItem item;
  final AppColors c;
  final AppLocalizations s;
  const _Trailing({required this.item, required this.c, required this.s});

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return s.relativeJustNow;
    if (diff.inMinutes < 60) return s.relativeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return s.relativeHoursAgo(diff.inHours);
    return s.relativeDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _relative(item.receivedAt),
          style: TypographyManager.textCaption.copyWith(color: c.fgMuted),
        ),
        if (item.unread) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.tagPurpleIcon,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
