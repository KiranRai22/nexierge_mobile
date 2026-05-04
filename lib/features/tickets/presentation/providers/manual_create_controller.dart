import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/entities/ticket_form_options.dart';
import '../../domain/models/ticket.dart';
import 'checked_in_guest_stays_provider.dart';
import 'my_tickets_notifier.dart';

@immutable
class ManualDraftState {
  final String summary;

  /// Display-only room number (e.g. "8"). Drives the room chip in the form.
  final String? selectedRoomNumber;

  /// `guest_stay_id` — wire field, taken from the checked-in stay row.
  final String? guestStayId;

  /// Primary contact for the picked stay. Sent as `contact_id`.
  final String? contactId;

  /// Auto-populated from the picked stay's `contact_details.full_name`.
  final String guestName;

  final HotelDepartment? department;
  final TicketSource? source;
  final String notes;
  final bool submitting;

  const ManualDraftState({
    this.summary = '',
    this.selectedRoomNumber,
    this.guestStayId,
    this.contactId,
    this.guestName = '',
    this.department,
    this.source,
    this.notes = '',
    this.submitting = false,
  });

  bool get canSubmit =>
      summary.trim().isNotEmpty &&
      guestStayId != null &&
      contactId != null &&
      department != null &&
      source != null &&
      !submitting;

  ManualDraftState copyWith({
    String? summary,
    String? selectedRoomNumber,
    String? guestStayId,
    String? contactId,
    bool clearRoom = false,
    String? guestName,
    HotelDepartment? department,
    TicketSource? source,
    bool clearSource = false,
    String? notes,
    bool? submitting,
  }) {
    return ManualDraftState(
      summary: summary ?? this.summary,
      selectedRoomNumber: clearRoom
          ? null
          : (selectedRoomNumber ?? this.selectedRoomNumber),
      guestStayId: clearRoom ? null : (guestStayId ?? this.guestStayId),
      contactId: clearRoom ? null : (contactId ?? this.contactId),
      guestName: clearRoom ? '' : (guestName ?? this.guestName),
      department: department ?? this.department,
      source: clearSource ? null : (source ?? this.source),
      notes: notes ?? this.notes,
      submitting: submitting ?? this.submitting,
    );
  }
}

class ManualDraftController extends AutoDisposeNotifier<ManualDraftState> {
  @override
  ManualDraftState build() => const ManualDraftState();

  void setSummary(String v) => state = state.copyWith(summary: v);

  /// Picker returns the `guest_stay_id`; we look up the row to also stamp
  /// the matching contact + display number + guest name in one shot.
  void selectGuestStay(String guestStayId) {
    final stay = ref.read(checkedInStayByIdProvider(guestStayId));
    if (stay == null) {
      debugPrint(
        '[ManualDraftController] selectGuestStay: no row for $guestStayId',
      );
      return;
    }
    state = state.copyWith(
      guestStayId: stay.guestStayId,
      contactId: stay.contactId,
      selectedRoomNumber: stay.roomNumber,
      guestName: stay.fullName,
    );
  }

  void clearRoom() => state = state.copyWith(clearRoom: true);

  void setDepartment(HotelDepartment d) =>
      state = state.copyWith(department: d);
  void setSource(TicketSource s) => state = state.copyWith(source: s);
  void setNotes(String v) => state = state.copyWith(notes: v);

  Future<String?> submit() async {
    if (!state.canSubmit) return null;

    final bootstrap = ref
        .read(dashboardBootstrapControllerProvider)
        .valueOrNull;
    final hotelId = bootstrap?.userProfile?.hotelDetails.hotel.id;
    if (hotelId == null || hotelId.isEmpty) {
      debugPrint('[ManualDraftController] No hotelId from bootstrap');
      return null;
    }

    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(ticketRepositoryProvider);
      final ticketId = await repo.createManualTicket(
        hotelId: hotelId,
        summary: state.summary.trim(),
        details: state.notes.trim(),
        departmentId: state.department?.id,
        guestStayId: state.guestStayId,
        contactId: state.contactId,
        source: state.source?.name,
      );

      // Realtime usually pushes the new ticket within a moment, but
      // refresh as a safety net so the Incoming/Today lists never miss
      // a just-created ticket if the WS frame is delayed or dropped.
      // Fire-and-forget — submit() shouldn't block on the refresh.
      // ignore: discarded_futures
      ref.read(myTicketsNotifierProvider.notifier).refresh();

      return ticketId;
    } finally {
      if (ref.exists(manualDraftControllerProvider)) {
        state = state.copyWith(submitting: false);
      }
    }
  }
}

final manualDraftControllerProvider =
    AutoDisposeNotifierProvider<ManualDraftController, ManualDraftState>(
      ManualDraftController.new,
    );
