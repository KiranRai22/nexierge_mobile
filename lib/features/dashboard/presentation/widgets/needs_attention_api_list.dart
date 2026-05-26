import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/theme/unified_theme_manager.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/needs_attention_item.dart';

/// "Needs attention" block using API data. Displays items from
/// dashboard/needs_attention endpoint, or shimmer while loading.
class NeedsAttentionApiList extends StatelessWidget {
  final List<NeedsAttentionItem> items;
  final bool isLoading;
  final VoidCallback onViewAll;
  final ValueChanged<String> onItemTap;
  final bool showHeader;

  const NeedsAttentionApiList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onViewAll,
    required this.onItemTap,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.dashboardNeedsAttention,
                style: TypographyManager.textHeading.copyWith(color: c.fgBase),
              ),
              if (!isLoading && items.isNotEmpty)
                _ViewAllButton(label: s.dashboardViewAll, onTap: onViewAll),
            ],
          ),
        // Needs attention list content
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: isLoading
              ? const _NeedsAttentionShimmer()
              : items.isEmpty
              ? const _AllClearEmpty()
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _AttentionRow(
                        item: items[i],
                        onTap: () => onItemTap(items[i].id),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return InkWell(
      onTap: tapSound(onTap),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: TypographyManager.textCaption.copyWith(color: c.tagPurpleIcon),
        ),
      ),
    );
  }
}

class _AllClearEmpty extends StatelessWidget {
  const _AllClearEmpty();

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.tagGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.checkCheck,
              color: c.tagGreenIcon,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.dashboardAllClearTitle,
            style: TypographyManager.textBodyStrong.copyWith(color: c.fgBase),
          ),
          const SizedBox(height: 4),
          Text(
            s.dashboardAllClearBody,
            textAlign: TextAlign.center,
            style: TypographyManager.textBody.copyWith(color: c.fgMuted),
          ),
          const SizedBox(height: 4),
          Text(
            s.dashboardAllClearHint,
            textAlign: TextAlign.center,
            style: TypographyManager.textMicro.copyWith(color: c.fgSubtle),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatefulWidget {
  final NeedsAttentionItem item;
  final VoidCallback onTap;

  const _AttentionRow({required this.item, required this.onTap});

  @override
  State<_AttentionRow> createState() => _AttentionRowState();
}

class _AttentionRowState extends State<_AttentionRow> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second to update elapsed time
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  NeedsAttentionItem get item => widget.item;
  VoidCallback get onTap => widget.onTap;

  ({Color iconBg, Color iconFg, Color pillBg, Color pillFg, String? emoji})
  _palette(AppColors c) {
    final bool isOverdue = item.dueAt > 0 && item.dueAt < DateTime.now().millisecondsSinceEpoch;

    switch (item.status) {
      case 'ACCEPTED':
        return (
          iconBg: c.tagBlueBg,
          iconFg: c.tagBlueIcon,
          pillBg: c.tagBlueBg,
          pillFg: c.tagBlueText,
          emoji: item.department.mobileIcon.isNotEmpty ? item.department.mobileIcon : null,
        );
      case 'NEW':
        return (
          iconBg: c.tagNeutralBg,
          iconFg: c.tagNeutralIcon,
          pillBg: isOverdue ? c.tagRedBg : c.tagNeutralBg,
          pillFg: isOverdue ? c.tagRedText : c.tagNeutralText,
          emoji: item.department.mobileIcon.isNotEmpty ? item.department.mobileIcon : null,
        );
      default:
        return (
          iconBg: isOverdue ? c.tagRedBg : c.tagOrangeBg,
          iconFg: isOverdue ? c.tagRedIcon : c.tagOrangeIcon,
          pillBg: isOverdue ? c.tagRedBg : c.tagOrangeBg,
          pillFg: isOverdue ? c.tagRedText : c.tagOrangeText,
          emoji: item.department.mobileIcon.isNotEmpty ? item.department.mobileIcon : null,
        );
    }
  }

  String _countdownText() {
    if (item.dueAt <= 0) return '';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = item.dueAt - now;

    if (diff <= 0) {
      // Overdue - show elapsed time since due
      final overdue = now - item.dueAt;
      return 'Overdue: ${_formatDuration(overdue)}';
    } else {
      // Not overdue - show remaining time
      return '⏱️ ${_formatDuration(diff)}';
    }
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final hours = (minutes / 60).floor();
    final days = (hours / 24).floor();

    if (days > 0) {
      return '${days}d ${hours % 24}h ${minutes % 60}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes % 60}m ${seconds % 60}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds % 60}s';
    } else {
      return '${seconds}s';
    }
  }

  String _pillLabel(AppLocalizations s) {
    switch (item.status) {
      case 'IN_PROGRESS':
        return _countdownText();
      case 'NEW':
        final elapsed = DateTime.now().millisecondsSinceEpoch - item.createdAt;
        return '⏳ ${_formatDuration(elapsed)}';
      case 'ACCEPTED':
        return s.dashboardNotStartedPill;
      case 'BACKLOG':
      case 'DONE':
        return '';
      default:
        return '';
    }
  }

  Color _timePillBg(AppColors c) {
    if (item.status == 'IN_PROGRESS' && item.dueAt > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (item.dueAt < now) return c.tagRedBg; // Overdue
    }
    return c.tagNeutralBg;
  }

  Color _timePillFg(AppColors c) {
    if (item.status == 'IN_PROGRESS' && item.dueAt > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (item.dueAt < now) return c.tagRedText; // Overdue
    }
    return c.tagNeutralText;
  }

  ({String label, Color bg, Color fg}) _statusBadge(AppColors c) {
    switch (item.status) {
      case 'NEW':
        return (label: 'NEW', bg: c.tagBlueBg, fg: c.tagBlueText);
      case 'ACCEPTED':
        return (label: 'ACCEPTED', bg: c.tagPurpleBg, fg: c.tagPurpleText);
      case 'IN_PROGRESS':
        return (label: 'IN PROGRESS', bg: c.tagOrangeBg, fg: c.tagOrangeText);
      case 'DONE':
        return (label: 'DONE', bg: c.tagGreenBg, fg: c.tagGreenText);
      case 'BACKLOG':
        return (label: 'BACKLOG', bg: c.tagNeutralBg, fg: c.tagNeutralText);
      default:
        return (label: item.status, bg: c.tagNeutralBg, fg: c.tagNeutralText);
    }
  }

  String _roomLabel() {
    return 'Room No: ${item.onbRoomNumber}';
  }

  String _departmentLabel() {
    return item.department.name;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.themeColors;
    final p = _palette(c);
    final radius = BorderRadius.circular(12);
    return Material(
      color: c.bgBase,
      borderRadius: radius,
      child: InkWell(
        onTap: () async {
          await SoundManager.instance.play(SoundCategory.card);
          onTap();
        },
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: c.borderBase, width: 1),
            boxShadow: [
              BoxShadow(
                color: c.borderBase.withValues(alpha: 0.04),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: c.borderBase.withValues(alpha: 0.04),
                offset: const Offset(0, 0),
                blurRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: p.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: p.emoji != null
                    ? Center(
                        child: Text(
                          p.emoji!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      )
                    : Icon(LucideIcons.circleDot, color: p.iconFg, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.guestName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypographyManager.textBodyStrong.copyWith(
                          color: c.fgBase,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _roomLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypographyManager.textMeta.copyWith(
                          color: c.fgMuted,
                        ),
                      ),
                      Text(
                        _departmentLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TypographyManager.textMeta.copyWith(
                          color: c.fgMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(
                      label: _statusBadge(c).label,
                      bg: _statusBadge(c).bg,
                      fg: _statusBadge(c).fg,
                    ),
                    if (_pillLabel(s).isNotEmpty) ...[  
                      const SizedBox(height: 4),
                      _SeverityPill(
                        label: _pillLabel(s),
                        bg: _timePillBg(c),
                        fg: _timePillFg(c),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _SeverityPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TypographyManager.textCaption.copyWith(color: fg),
      ),
    );
  }
}

/// Status badge showing ticket status with color coding
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _StatusBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TypographyManager.textCaption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NeedsAttentionShimmer extends StatelessWidget {
  const _NeedsAttentionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ShimmerRow(),
        ],
      ],
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBase, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: c.borderBase.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: c.borderBase.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 24,
              decoration: BoxDecoration(
                color: c.borderBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
