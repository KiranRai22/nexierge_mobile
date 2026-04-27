import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../domain/models/ticket.dart';

/// Two-up info cards (Room · Guest). Stack to one column under 360 dp.
class InfoCardsRow extends StatelessWidget {
  final Ticket ticket;
  const InfoCardsRow({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final cards = [
          _InfoCard(
            label: s.detailRoomLabel,
            primary: s.roomNumber(ticket.room.number),
            secondary: ticket.room.type ?? s.roomFloor(ticket.room.floor),
          ),
          _InfoCard(
            label: s.detailGuestLabel,
            primary: ticket.guest?.displayName ?? s.detailEmpty,
            secondary: ticket.guest?.statusLine ?? s.detailEmpty,
          ),
        ];
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cards[0],
              const SizedBox(height: 8),
              cards[1],
            ],
          );
        }
        // Wrap in IntrinsicHeight so `crossAxisAlignment: stretch` resolves
        // inside a vertical ListView (which gives the Row unbounded height
        // by default — causes a "RenderBox was not laid out" assertion).
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 8),
              Expanded(child: cards[1]),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String primary;
  final String secondary;

  const _InfoCard({
    required this.label,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPalette.opsSurfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.opsBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TypographyManager.kpiLabel),
          const SizedBox(height: 8),
          Text(
            primary,
            style: TypographyManager.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            secondary,
            style: TypographyManager.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
