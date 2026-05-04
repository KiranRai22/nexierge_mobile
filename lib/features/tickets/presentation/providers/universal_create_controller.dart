import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/models/universal_catalog.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart';
import '../../data/services/universal_request_service.dart';
import '../../data/dtos/universal_request_order_dto.dart';
import 'checked_in_guest_stays_provider.dart';
import 'repository_providers.dart';
import 'session_providers.dart';

/// Re-export the dynamic catalog item so existing widget imports of this
/// file keep compiling without each one needing to add a second import.
export '../../domain/models/universal_catalog.dart' show UniversalItem;

/// Step in the 2-step Universal create wizard.
enum UniversalStep { selectItems, fillDetails }

/// One picked line in the draft (item + quantity).
@immutable
class PickedLine {
  final UniversalItem item;
  final int quantity;
  const PickedLine({required this.item, this.quantity = 1});

  PickedLine copyWith({int? quantity}) =>
      PickedLine(item: item, quantity: quantity ?? this.quantity);
}

/// Draft state for the create screen.
@immutable
class UniversalDraftState {
  final UniversalStep step;
  final Map<String, PickedLine> picks; // keyed by item id
  /// guest_stay_id of the picked checked-in stay. Field name retained for
  /// state-shape stability with earlier versions of this controller.
  final String? selectedRoomId;
  /// contact_id of the guest on the picked stay. Used as the order's
  /// contact when posting `/universal_requests/order/create`.
  final String? contactId;
  /// Display room number from the picked stay (e.g. "204"). Rendered in
  /// the room field on the details step.
  final String? selectedRoomNumber;
  final String guestName;
  final TicketSource? source;
  final String note;
  final bool submitting;

  const UniversalDraftState({
    this.step = UniversalStep.selectItems,
    this.picks = const {},
    this.selectedRoomId,
    this.contactId,
    this.selectedRoomNumber,
    this.guestName = '',
    this.source,
    this.note = '',
    this.submitting = false,
  });

  bool get canContinue => picks.isNotEmpty;

  bool get canSubmit =>
      picks.isNotEmpty &&
      selectedRoomId != null &&
      source != null &&
      !submitting;

  bool isPicked(String itemId) => picks.containsKey(itemId);

  int quantity(String itemId) => picks[itemId]?.quantity ?? 0;

  int get totalUnits =>
      picks.values.fold<int>(0, (acc, p) => acc + p.quantity);

  /// Auto-routed department inferred from the first picked item's
  /// backend department. Falls back to housekeeping when no items.
  Department get autoDepartment {
    if (picks.isEmpty) return Department.housekeeping;
    return picks.values.first.item.department;
  }

  /// Backend uuid for the auto-routed department. Used when posting the
  /// universal request order so the server routes to the right team.
  String? get autoDepartmentId {
    if (picks.isEmpty) return null;
    return picks.values.first.item.departmentId;
  }

  UniversalDraftState copyWith({
    UniversalStep? step,
    Map<String, PickedLine>? picks,
    String? selectedRoomId,
    String? contactId,
    String? selectedRoomNumber,
    bool clearRoom = false,
    String? guestName,
    TicketSource? source,
    bool clearSource = false,
    String? note,
    bool? submitting,
  }) {
    return UniversalDraftState(
      step: step ?? this.step,
      picks: picks ?? this.picks,
      selectedRoomId:
          clearRoom ? null : (selectedRoomId ?? this.selectedRoomId),
      contactId: clearRoom ? null : (contactId ?? this.contactId),
      selectedRoomNumber: clearRoom
          ? null
          : (selectedRoomNumber ?? this.selectedRoomNumber),
      guestName: clearRoom ? '' : (guestName ?? this.guestName),
      source: clearSource ? null : (source ?? this.source),
      note: note ?? this.note,
      submitting: submitting ?? this.submitting,
    );
  }
}

/// AutoDispose notifier — state is local to the create screen.
class UniversalDraftController
    extends AutoDisposeNotifier<UniversalDraftState> {
  @override
  UniversalDraftState build() => const UniversalDraftState();

  void togglePick(UniversalItem item) {
    final next = {...state.picks};
    if (next.containsKey(item.id)) {
      next.remove(item.id);
    } else {
      next[item.id] = PickedLine(item: item);
    }
    state = state.copyWith(picks: next);
  }

  void setQuantity(String itemId, int qty) {
    final existing = state.picks[itemId];
    if (existing == null) return;
    final clamped = qty.clamp(1, 99);
    state = state.copyWith(
      picks: {...state.picks, itemId: existing.copyWith(quantity: clamped)},
    );
  }

  void clearAllPicks() {
    state = state.copyWith(picks: const {});
  }

  /// Picker returns the `guest_stay_id`. Same flow as
  /// `ManualDraftController.selectGuestStay`: look up the row, stamp
  /// guest_stay_id + contact_id + room number + guest name in one shot.
  ///
  /// If the picked stay has no name on file, [guestName] is intentionally
  /// blanked rather than left at its previous value — the operator can
  /// still type one in by hand.
  void selectRoom(String guestStayId) {
    final stay = ref.read(checkedInStayByIdProvider(guestStayId));
    if (stay == null) {
      debugPrint(
        '[UniversalDraftController] selectRoom: no stay row for $guestStayId',
      );
      return;
    }
    state = state.copyWith(
      selectedRoomId: stay.guestStayId,
      contactId: stay.contactId,
      selectedRoomNumber: stay.roomNumber,
      guestName: stay.fullName,
    );
  }

  void clearRoom() => state = state.copyWith(clearRoom: true);

  void setGuestName(String v) => state = state.copyWith(guestName: v);

  void setSource(TicketSource s) => state = state.copyWith(source: s);

  void setNote(String note) => state = state.copyWith(note: note);

  void goToDetails() {
    if (!state.canContinue) return;
    state = state.copyWith(step: UniversalStep.fillDetails);
  }

  void backToSelection() =>
      state = state.copyWith(step: UniversalStep.selectItems);

  /// Submits the draft. Returns the created ticket id, or null if invalid.
  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      ref.read(operatorSessionProvider);

      final ticket = await repo.create(_buildDraft());
      await _createUniversalOrder();

      return ticket.id;
    } finally {
      if (ref.exists(universalDraftControllerProvider)) {
        state = state.copyWith(submitting: false);
      }
    }
  }

  Future<void> _createUniversalOrder() async {
    final userProfile = ref.read(userProfileProvider);
    if (userProfile == null) return;

    final universalRequestService = ref.read(universalRequestServiceProvider);

    final orderItems = state.picks.values
        .map((pick) => OrderItemDto(
              activeUniversalRequestId: pick.item.id,
              guestNotes: state.note.trim(),
              price: 0.0,
              quantity: pick.quantity,
              itemName: pick.item.title,
            ))
        .toList();

    try {
      await universalRequestService.createOrder(
        guestStayId: state.selectedRoomId ?? '',
        contactId: state.contactId ?? userProfile.id,
        hotelId: userProfile.userHotelStatus.hotelId,
        orderItems: orderItems,
      );
    } catch (_) {
      // Ticket creation must succeed even if order POST fails — the local
      // ticket is the source of truth for the operator.
    }
  }

  NewTicketDraft _buildDraft() {
    final picks = state.picks.values.toList();
    final title = picks.length == 1
        ? '${picks.first.item.title}${picks.first.quantity > 1 ? ' (${picks.first.quantity})' : ''}'
        : picks.map((p) => p.item.title.toLowerCase()).join(', ');
    final items = [
      for (final p in picks)
        RequestItem(
          id: p.item.id,
          title: p.item.title,
          subtitle: p.item.departmentName,
          quantity: p.quantity,
        ),
    ];
    final guest = state.guestName.trim();
    return NewTicketDraft(
      title: _capitalize(title),
      kind: TicketKind.universal,
      department: state.autoDepartment,
      roomId: state.selectedRoomId!,
      items: items,
      note: state.note.trim().isEmpty ? null : state.note.trim(),
      source: state.source,
      guestName: guest.isEmpty ? null : guest,
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

final universalDraftControllerProvider = AutoDisposeNotifierProvider<
    UniversalDraftController, UniversalDraftState>(
  UniversalDraftController.new,
);

/// Available rooms (delegated to repo). Cheap getter; rebuilds rarely.
final availableRoomsProvider = Provider<List<Room>>((ref) {
  return ref.watch(ticketsRepositoryProvider).rooms();
});
