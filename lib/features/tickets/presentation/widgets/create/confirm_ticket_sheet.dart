import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/color_palette.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/models/catalog.dart';
import '../../../domain/models/ticket.dart';
import '../../providers/catalog_create_controller.dart';
import '../../providers/checked_in_guest_stays_provider.dart';
import '../../screens/create_screen.dart' show formatMoney;

/// Confirm Ticket bottom sheet shown before submission.
///
/// Returns `true` when the user taps Confirm; `null` otherwise.
class ConfirmTicketSheet {
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorPalette.opsSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ConfirmBody(),
    );
  }
}

class _ConfirmBody extends ConsumerWidget {
  const _ConfirmBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.l10n;
    final draft = ref.watch(catalogDraftControllerProvider);
    final catalog = draft.catalog;
    if (catalog == null) return const SizedBox.shrink();

    // selectedRoomId now stores the picked checked-in stay's guest_stay_id
    // (was: room id from the legacy form-options API). Look up the display
    // room number from the checked-in stays cache.
    final stay = draft.selectedRoomId == null
        ? null
        : ref.watch(checkedInStayByIdProvider(draft.selectedRoomId!));
    final guest = draft.guestName.trim();
    final note = draft.note.trim();

    final rows = <_SummaryRow>[
      _SummaryRow.inline(s.confirmTicketRowCatalog, catalog.name),
      _SummaryRow.inline(
        s.confirmTicketRowDepartment,
        catalog.department.label(s),
      ),
      _SummaryRow.inline(
        s.confirmTicketRowRoom,
        stay == null ? '—' : s.roomNumber(stay.roomNumber),
      ),
      if (guest.isNotEmpty) _SummaryRow.inline(s.confirmTicketRowGuest, guest),
      _SummaryRow.inline(
        s.confirmTicketRowSource,
        draft.source == null ? '—' : _sourceLabel(s, draft.source!),
      ),
      _SummaryRow.inline(
        s.confirmTicketRowTotal,
        formatMoney(draft.total),
        emphasize: true,
      ),
      if (note.isNotEmpty)
        _SummaryRow.block(s.confirmTicketRowNotes, note),
    ];

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              const _Handle(),
              _Header(onClose: () => Navigator.of(context).pop()),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _SummaryBlock(rows: rows),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        s.confirmTicketItemsHeading(draft.cart.length),
                        style: TypographyManager.sectionOverline,
                      ),
                    ),
                    _ItemsBlock(cart: draft.cart),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorPalette.textPrimary,
                          side: BorderSide(color: ColorPalette.opsBorder),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TypographyManager.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(s.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.textPrimary,
                          foregroundColor: ColorPalette.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TypographyManager.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(s.confirmTicketCta),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _sourceLabel(AppLocalizations s, TicketSource src) {
  switch (src) {
    case TicketSource.whatsApp:
      return s.createSourceWhatsApp;
    case TicketSource.guestApp:
      return s.ticketSourceGuestApp;
    case TicketSource.frontDesk:
      return s.createSourceFrontDesk;
    case TicketSource.phone:
      return s.createSourcePhone;
    case TicketSource.walkIn:
      return s.createSourceInPerson;
    case TicketSource.system:
      return s.createSourceInternal;
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: ColorPalette.opsBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.confirmTicketTitle,
              style: TypographyManager.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: ColorPalette.textSecondary,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  final bool block;
  final bool emphasize;

  const _SummaryRow.inline(this.label, this.value, {this.emphasize = false})
      : block = false;
  const _SummaryRow.block(this.label, this.value)
      : block = true,
        emphasize = false;
}

class _SummaryBlock extends StatelessWidget {
  final List<_SummaryRow> rows;
  const _SummaryBlock({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.opsBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: rows[i].block
                  ? _BlockRow(row: rows[i])
                  : _InlineRow(row: rows[i]),
            ),
            if (i != rows.length - 1)
              Divider(height: 1, color: ColorPalette.opsBorder),
          ],
        ],
      ),
    );
  }
}

class _InlineRow extends StatelessWidget {
  final _SummaryRow row;
  const _InlineRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            row.label,
            style: TypographyManager.bodySmall.copyWith(
              color: ColorPalette.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Text(
          row.value,
          style: TypographyManager.bodyMedium.copyWith(
            color: ColorPalette.textPrimary,
            fontWeight: row.emphasize ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BlockRow extends StatelessWidget {
  final _SummaryRow row;
  const _BlockRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.label,
          style: TypographyManager.bodySmall.copyWith(
            color: ColorPalette.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          row.value,
          style: TypographyManager.bodyMedium.copyWith(
            color: ColorPalette.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ItemsBlock extends StatelessWidget {
  final List<CartLine> cart;
  const _ItemsBlock({required this.cart});

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final perItemIndex = <String, int>{};
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.opsSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.opsBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < cart.length; i++) ...[
            Builder(
              builder: (_) {
                final line = cart[i];
                final n = (perItemIndex[line.item.id] ?? 0) + 1;
                perItemIndex[line.item.id] = n;
                final summary = line.optionsSummary;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: ColorPalette.opsSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ColorPalette.opsBorder),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              line.item.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ColorPalette.opsPurpleSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'x${line.quantity}',
                              style: TypographyManager.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.opsPurpleDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              line.item.name,
                              style: TypographyManager.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatMoney(line.lineTotal),
                            style: TypographyManager.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (line.item.hasOptions && summary.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 36),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.catalogLineLabel(n, summary),
                                  style: TypographyManager.bodySmall.copyWith(
                                    color: ColorPalette.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formatMoney(line.lineTotal),
                                style: TypographyManager.bodySmall.copyWith(
                                  color: ColorPalette.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (i != cart.length - 1)
              Divider(height: 1, color: ColorPalette.opsBorder),
          ],
        ],
      ),
    );
  }
}
