import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/string_utils.dart';
import '../../domain/entities/checked_in_guest_stay.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/models/universal_catalog.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart';
import '../../data/services/universal_request_service.dart';
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

  /// Actual room UUID (`room_details.id`). Used to filter guests for the same room.
  final String? roomId;

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
    this.roomId,
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

  int get totalUnits => picks.values.fold<int>(0, (acc, p) => acc + p.quantity);

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
    String? roomId,
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
      selectedRoomId: clearRoom
          ? null
          : (selectedRoomId ?? this.selectedRoomId),
      roomId: clearRoom ? null : (roomId ?? this.roomId),
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
/// Result type for universal order creation attempt.
typedef _OrderResult = ({bool success, Object? lastError});

class UniversalDraftController
    extends AutoDisposeNotifier<UniversalDraftState> {
  @override
  UniversalDraftState build() => const UniversalDraftState();

  /// Reset to initial state for consecutive ticket creation.
  void reset() => state = const UniversalDraftState();

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
      picks: {
        ...state.picks,
        itemId: existing.copyWith(quantity: clamped),
      },
    );
  }

  void clearAllPicks() {
    state = state.copyWith(picks: const {});
  }

  void selectRoom(CheckedInGuestStay stay) {
    state = state.copyWith(
      selectedRoomId: stay.guestStayId,
      roomId: stay.roomId,
      contactId: stay.contactId,
      selectedRoomNumber: stay.roomNumber,
      guestName: '',  // operator picks guest separately
    );
  }

  void selectGuest(CheckedInGuestStay guest) {
    state = state.copyWith(
      selectedRoomId: guest.guestStayId,
      contactId: guest.contactId,
      guestName: StringUtils.capitalizeFirst(guest.fullName),
    );
  }

  void clearRoom() => state = state.copyWith(clearRoom: true);

  void setGuestName(String v) =>
      state = state.copyWith(guestName: StringUtils.capitalizeFirst(v));

  void setSource(TicketSource s) => state = state.copyWith(source: s);

  void setNote(String note) =>
      state = state.copyWith(note: StringUtils.capitalizeFirst(note));

  void goToDetails() {
    if (!state.canContinue) return;
    state = state.copyWith(step: UniversalStep.fillDetails);
  }

  void backToSelection() =>
      state = state.copyWith(step: UniversalStep.selectItems);

  /// Submits the draft. Returns the created ticket id, or null if invalid.
  /// Throws [UniversalOrderException] if ticket was created but universal order failed.
  Future<String?> submit({void Function(String)? onRetryMessage}) async {
    if (!state.canSubmit) return null;
    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      ref.read(operatorSessionProvider);

      final ticket = await repo.create(_buildDraft());
      
      // Try to create universal order with retry logic
      final orderResult = await _createUniversalOrderWithRetry(
        onRetryMessage: onRetryMessage,
      );
      
      if (!orderResult.success) {
        // Log the error details for diagnostic sharing
        await _logErrorToFile(
          'Universal order creation failed after 2 attempts. Ticket ID: ${ticket.id}',
          orderResult.lastError ?? 'Unknown error',
        );
        
        // Ticket was created but universal order failed after retries
        // We still return the ticket ID but mark it as partial success
        throw UniversalOrderException(
          ticketId: ticket.id,
          message: 'Ticket created but universal order details failed to save.',
        );
      }

      return ticket.id;
    } finally {
      if (ref.exists(universalDraftControllerProvider)) {
        state = state.copyWith(submitting: false);
      }
    }
  }

  /// Creates universal order with 1 retry attempt on timeout.
  /// Returns result with success flag and last error if failed.
  Future<_OrderResult> _createUniversalOrderWithRetry({
    void Function(String)? onRetryMessage,
  }) async {
    Object? lastError;

    // First attempt
    try {
      final success = await _tryCreateUniversalOrder();
      if (success) return (success: true, lastError: null);
    } catch (e) {
      lastError = e;
    }

    // Notify about retry attempt
    //debugPrint('[UniversalDraftController] First attempt failed, retrying...');
    onRetryMessage?.call('Ticket creation failed. Attempting to create again....');

    // Second attempt (immediate retry)
    try {
      final success = await _tryCreateUniversalOrder();
      if (success) return (success: true, lastError: null);
    } catch (e) {
      lastError = e;
    }

    // Both attempts failed
    return (success: false, lastError: lastError);
  }

  /// Single attempt to create universal order.
  /// Returns true on success, false on failure (does not throw).
  Future<bool> _tryCreateUniversalOrder() async {
    final userProfile = ref.read(userProfileProvider);
    if (userProfile == null) return false;

    final universalRequestService = ref.read(universalRequestServiceProvider);

    final submission = UniversalOrderSubmission(
      hotelId: userProfile.userHotelStatus.hotelId,
      guestStayId: state.selectedRoomId ?? '',
      contactId: state.contactId ?? userProfile.id,
      notes: state.note,
      items: state.picks.values
          .map(
            (pick) => UniversalOrderItem(
              itemId: pick.item.id,
              itemName: pick.item.title,
              quantity: pick.quantity,
            ),
          )
          .toList(growable: false),
    );

    try {
      await universalRequestService.createOrder(submission: submission);
      return true;
    } on Exception {
      //debugPrint('[UniversalDraftController] Order creation failed: $e');
      return false;
    }
  }

  /// Logs error details to a file for future diagnostic sharing.
  /// File location: app documents directory /nexierge_logs.txt
  Future<void> _logErrorToFile(String message, Object error) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/nexierge_logs.txt');
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] $message\nError: $error\n\n';
      
      // Append to file (create if doesn't exist)
      await file.writeAsString(logEntry, mode: FileMode.append, flush: true);
      
      //debugPrint('[UniversalDraftController] Error logged to: ${file.path}');
    } catch (e) {
      // If logging fails, just print to console
      //debugPrint('[UniversalDraftController] Failed to log error: $e');
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

/// Exception thrown when ticket was created but universal order failed.
/// This allows the UI to show appropriate retry/error messaging.
class UniversalOrderException implements Exception {
  final String ticketId;
  final String message;
  
  const UniversalOrderException({
    required this.ticketId,
    required this.message,
  });
  
  @override
  String toString() => 'UniversalOrderException: $message (ticketId: $ticketId)';
}

final universalDraftControllerProvider =
    AutoDisposeNotifierProvider<UniversalDraftController, UniversalDraftState>(
      UniversalDraftController.new,
    );

/// Available rooms (delegated to repo). Cheap getter; rebuilds rarely.
final availableRoomsProvider = Provider<List<Room>>((ref) {
  return ref.watch(ticketsRepositoryProvider).rooms();
});
