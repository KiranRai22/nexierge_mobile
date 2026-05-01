import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ticket_form_options.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'repository_providers.dart';

@immutable
class ManualDraftState {
  final String summary;
  final String? selectedRoomId;
  final String guestName;
  final HotelDepartment? department;
  final TicketSource? source;
  final String notes;
  final bool submitting;

  const ManualDraftState({
    this.summary = '',
    this.selectedRoomId,
    this.guestName = '',
    this.department,
    this.source,
    this.notes = '',
    this.submitting = false,
  });

  bool get canSubmit =>
      summary.trim().isNotEmpty &&
      selectedRoomId != null &&
      department != null &&
      source != null &&
      !submitting;

  ManualDraftState copyWith({
    String? summary,
    String? selectedRoomId,
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
      selectedRoomId:
          clearRoom ? null : (selectedRoomId ?? this.selectedRoomId),
      guestName: guestName ?? this.guestName,
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
  void selectRoom(String id) => state = state.copyWith(selectedRoomId: id);
  void clearRoom() => state = state.copyWith(clearRoom: true);
  void setGuestName(String v) => state = state.copyWith(guestName: v);
  void setDepartment(HotelDepartment d) =>
      state = state.copyWith(department: d);
  void setSource(TicketSource s) => state = state.copyWith(source: s);
  void setNotes(String v) => state = state.copyWith(notes: v);

  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      // Map API HotelDepartment back to the legacy enum so the mock store
      // (which still types department as Department) accepts the draft.
      // Backend create endpoint will use department.id directly when wired.
      final fallback = state.department!.known ?? Department.housekeeping;
      final ticket = await repo.create(
        NewTicketDraft(
          title: state.summary.trim(),
          kind: TicketKind.manual,
          department: fallback,
          roomId: state.selectedRoomId!,
          items: const [],
          note: state.notes.trim().isEmpty ? null : state.notes.trim(),
          source: state.source,
          guestName:
              state.guestName.trim().isEmpty ? null : state.guestName.trim(),
        ),
      );
      return ticket.id;
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
