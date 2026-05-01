import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/department.dart';
import '../../domain/models/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'repository_providers.dart';
import 'session_providers.dart';

/// Category key constants.
enum UniversalCategory { housekeeping, fnb, frontDesk, maintenance }

extension UniversalCategoryX on UniversalCategory {
  /// Department auto-routed for this category.
  Department get autoDepartment {
    switch (this) {
      case UniversalCategory.housekeeping:
        return Department.housekeeping;
      case UniversalCategory.fnb:
        return Department.fnb;
      case UniversalCategory.frontDesk:
        return Department.frontDesk;
      case UniversalCategory.maintenance:
        return Department.maintenance;
    }
  }
}

/// Step in the 2-step Universal create wizard.
enum UniversalStep { selectItems, fillDetails }

/// Catalog of canned items organized by category.
class UniversalCatalog {
  static const List<UniversalItem> items = [
    UniversalItem(
      id: 'u_extra_towels',
      emoji: '🧺',
      category: UniversalCategory.housekeeping,
    ),
    UniversalItem(
      id: 'u_extra_pillows',
      emoji: '🛏️',
      category: UniversalCategory.housekeeping,
    ),
    UniversalItem(
      id: 'u_toiletries_kit',
      emoji: '🧴',
      category: UniversalCategory.housekeeping,
    ),
    UniversalItem(
      id: 'u_extra_blanket',
      emoji: '🛌',
      category: UniversalCategory.housekeeping,
    ),
    UniversalItem(
      id: 'u_room_cleaning',
      emoji: '🪣',
      category: UniversalCategory.housekeeping,
    ),
    UniversalItem(
      id: 'u_water_bottles',
      emoji: '💧',
      category: UniversalCategory.fnb,
    ),
    UniversalItem(
      id: 'u_ice_bucket',
      emoji: '🧊',
      category: UniversalCategory.fnb,
    ),
    UniversalItem(
      id: 'u_concierge_help',
      emoji: '🛎️',
      category: UniversalCategory.frontDesk,
    ),
    UniversalItem(
      id: 'u_climate_control',
      emoji: '🌡️',
      category: UniversalCategory.frontDesk,
    ),
    UniversalItem(
      id: 'u_light_fixture',
      emoji: '💡',
      category: UniversalCategory.maintenance,
    ),
    UniversalItem(
      id: 'u_plumbing_issue',
      emoji: '🚰',
      category: UniversalCategory.maintenance,
    ),
  ];

  static List<UniversalItem> byCategory(UniversalCategory cat) =>
      items.where((i) => i.category == cat).toList();

  static List<UniversalItem> search(String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((i) => i.id.replaceAll('_', ' ').contains(q)).toList();
  }
}

/// Catalog item — purely a UI shape.
@immutable
class UniversalItem {
  final String id;
  final String emoji;
  final UniversalCategory category;

  const UniversalItem({
    required this.id,
    required this.emoji,
    required this.category,
  });

  /// Human-readable title derived from id (e.g. u_extra_towels → "Extra towels").
  String get title {
    final slug = id.replaceFirst('u_', '').replaceAll('_', ' ');
    return '${slug[0].toUpperCase()}${slug.substring(1)}';
  }

  String get subtitle {
    switch (category) {
      case UniversalCategory.housekeeping:
        return 'Housekeeping';
      case UniversalCategory.fnb:
        return 'F&B';
      case UniversalCategory.frontDesk:
        return 'Front Desk';
      case UniversalCategory.maintenance:
        return 'Maintenance';
    }
  }
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
  final UniversalStep step;
  final Map<String, PickedLine> picks; // keyed by item id
  final String? selectedRoomId;
  final String guestName;
  final TicketSource? source;
  final String note;
  final bool submitting;

  const UniversalDraftState({
    this.step = UniversalStep.selectItems,
    this.picks = const {},
    this.selectedRoomId,
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

  /// Auto-routed department inferred from the first picked item's category.
  /// Falls back to housekeeping if no items.
  Department get autoDepartment {
    if (picks.isEmpty) return Department.housekeeping;
    return picks.values.first.item.category.autoDepartment;
  }

  UniversalDraftState copyWith({
    UniversalStep? step,
    Map<String, PickedLine>? picks,
    String? selectedRoomId,
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
      guestName: guestName ?? this.guestName,
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

  void selectRoom(String roomId) =>
      state = state.copyWith(selectedRoomId: roomId);

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
      // Operator session retained for potential future fallbacks.
      ref.read(operatorSessionProvider);
      final ticket = await repo.create(_buildDraft());
      return ticket.id;
    } finally {
      if (ref.exists(universalDraftControllerProvider)) {
        state = state.copyWith(submitting: false);
      }
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
          subtitle: p.item.subtitle,
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
