import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../domain/models/ticket.dart';
import '../providers/ticket_detail_controller.dart';
import '../widgets/detail/eta_bottom_sheet.dart';
import '../widgets/detail/guest_note_callout.dart';
import '../widgets/detail/header_chips.dart';
import '../widgets/detail/info_cards_row.dart';
import '../widgets/detail/request_list.dart';
import '../widgets/detail/timing_stepper.dart';

/// Ticket detail page. Reactive — re-renders whenever the repository emits.
class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTicket = ref.watch(ticketByIdProvider(ticketId));

    return Scaffold(
      backgroundColor: ColorPalette.opsSurface,
      appBar: _DetailAppBar(asyncTicket: asyncTicket),
      body: asyncTicket.when(
        data: (t) => t == null ? const _MissingView() : _DetailBody(ticket: t),
        loading: () => const _LoadingView(),
        error: (e, st) => _ErrorView(error: e.toString()),
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AsyncValue<Ticket?> asyncTicket;
  const _DetailAppBar({required this.asyncTicket});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final code = asyncTicket.maybeWhen(
      data: (t) => t?.code ?? '',
      orElse: () => '',
    );
    return AppBar(
      backgroundColor: ColorPalette.opsSurface,
      foregroundColor: ColorPalette.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        code,
        style: TypographyManager.screenTitle,
      ),
      centerTitle: true,
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Ticket ticket;
  const _DetailBody({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                ticket.title,
                style: TypographyManager.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              HeaderChips(ticket: ticket),
              const SizedBox(height: 16),
              InfoCardsRow(ticket: ticket),
              const SizedBox(height: 16),
              if (ticket.items.isNotEmpty) ...[
                RequestList(items: ticket.items),
                const SizedBox(height: 16),
              ],
              if (ticket.note != null && ticket.note!.isNotEmpty) ...[
                GuestNoteCallout(note: ticket.note!),
                const SizedBox(height: 16),
              ],
              TimingStepper(ticket: ticket),
            ],
          ),
        ),
        _ActionBar(ticket: ticket),
      ],
    );
  }
}

class _ActionBar extends ConsumerStatefulWidget {
  final Ticket ticket;
  const _ActionBar({required this.ticket});

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  Future<void> _withGuard(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onAccept() async {
    final picked = await EtaBottomSheet.show(
      context,
      ticketCode: widget.ticket.code,
    );
    if (picked == null) return;
    await _withGuard(() =>
        ref.read(ticketActionsProvider).accept(widget.ticket.id, picked));
  }

  Future<void> _onMarkDone() async {
    await _withGuard(
        () => ref.read(ticketActionsProvider).markDone(widget.ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final t = widget.ticket;
    final isDoneOrCancelled = t.status == TicketStatus.done ||
        t.status == TicketStatus.cancelled;
    if (isDoneOrCancelled) {
      return const SizedBox.shrink();
    }
    final isInProgress = t.status == TicketStatus.inProgress ||
        t.status == TicketStatus.accepted;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: ColorPalette.opsBorder),
                foregroundColor: ColorPalette.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(s.actionChangeDept),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  _busy ? null : (isInProgress ? _onMarkDone : _onAccept),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.opsPurple,
                foregroundColor: ColorPalette.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TypographyManager.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.white,
                ),
              ),
              child: Text(
                isInProgress
                    ? s.actionMarkDone
                    : s.actionAccept,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: ColorPalette.opsPurple),
    );
  }
}

class _MissingView extends StatelessWidget {
  const _MissingView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.notFoundError,
          textAlign: TextAlign.center,
          style: TypographyManager.bodyMedium,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: ColorPalette.statusOverdue,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.unknownError,
              style: TypographyManager.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: TypographyManager.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
