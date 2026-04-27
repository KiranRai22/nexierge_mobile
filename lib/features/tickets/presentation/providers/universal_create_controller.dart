import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'repository_providers.dart';
import 'session_providers.dart';

/// Catalog of canned items the operator can pick on the Universal create
/// screen. Mirrors the prototype's grid (Towels · Pillows · Toiletries ·
/// Blanket · Water · Other).
class UniversalCatalog {
  static const List<UniversalItem> items = [
    UniversalItem(
      id: 'u_towels',
      title: 'Towels',
      subtitle: 'Bath',
    ),
    UniversalItem(
      id: 'u_pillows',
      title: 'Pillows',
      subtitle: 'Standard',
    ),
    UniversalItem(
      id: 'u_toiletries',
      title: 'Toiletries',
      subtitle: 'Complete set',
    ),
    UniversalItem(
      id: 'u_blanket',
      title: 'Blanket',
      subtitle: 'Extra',
    ),
    UniversalItem(
      id: 'u_water',
      title: 'Water',
      subtitle: 'Bottled',
    ),
    UniversalItem(
      id: 'u_other',
      title: 'Other',
      subtitle: 'Free-form',
    ),
  ];
}

/// Catalog item — purely a UI shape.
@immutable
class UniversalItem {
  final String id;
  final String title;
  final String subtitle;
  const UniversalItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

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
  final Map<String, PickedLine> picks; // keyed by item id
  final String? selectedRoomId;
  final String note;
  final bool submitting;

  const UniversalDraftState({
    this.picks = const {},
    this.selectedRoomId,
    this.note = '',
    this.submitting = false,
  });

  bool get canSubmit =>
      picks.isNotEmpty && selectedRoomId != null && !submitting;

  bool isPicked(String itemId) => picks.containsKey(itemId);

  int quantity(String itemId) => picks[itemId]?.quantity ?? 0;

  UniversalDraftState copyWith({
    Map<String, PickedLine>? picks,
    String? selectedRoomId,
    bool clearRoom = false,
    String? note,
    bool? submitting,
  }) {
    return UniversalDraftState(
      picks: picks ?? this.picks,
      selectedRoomId: clearRoom ? null : (selectedRoomId ?? this.selectedRoomId),
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

  void selectRoom(String roomId) {
    state = state.copyWith(selectedRoomId: roomId);
  }

  void clearRoom() => state = state.copyWith(clearRoom: true);

  void setNote(String note) => state = state.copyWith(note: note);

  /// Submits the draft. Returns the created ticket id, or null if invalid.
  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      final session = ref.read(operatorSessionProvider);
      final ticket = await repo.create(_buildDraft(session.homeDepartment));
      return ticket.id;
    } finally {
      if (ref.exists(universalDraftControllerProvider)) {
        state = state.copyWith(submitting: false);
      }
    }
  }

  NewTicketDraft _buildDraft(Department dept) {
    final picks = state.picks.values.toList();
    final title = picks.length == 1
        ? '${picks.first.item.title}${picks.first.quantity > 1 ? ' (${picks.first.quantity})' : ''}'
        : picks.map((p) => p.item.title.toLowerCase()).join(', ');
    final items = [
      for (final p in picks)
        RequestItem(
          id: p.item.id,
          title: p.item.title,
          subtitle: p.item.subtitle,
          quantity: p.quantity,
        ),
    ];
    return NewTicketDraft(
      title: _capitalize(title),
      kind: TicketKind.universal,
      department: dept,
      roomId: state.selectedRoomId!,
      items: items,
      note: state.note.trim().isEmpty ? null : state.note.trim(),
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
