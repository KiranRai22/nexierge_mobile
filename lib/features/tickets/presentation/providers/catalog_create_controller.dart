import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/catalog_seed.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/ticket.dart';
import '../../domain/repositories/tickets_repository.dart';
import 'repository_providers.dart';

/// Three-step Catalog create flow:
///   1. selectCatalog — pick which catalog to order from
///   2. selectItems — browse menu, build cart
///   3. fillDetails — room/guest/source/notes/confirm
enum CatalogStep { selectCatalog, selectItems, fillDetails }

@immutable
class CatalogDraftState {
  final CatalogStep step;
  final String? selectedCatalogId;
  final List<CartLine> cart;
  final String? selectedRoomId;
  final String guestName;
  final TicketSource? source;
  final String note;
  final bool submitting;

  const CatalogDraftState({
    this.step = CatalogStep.selectCatalog,
    this.selectedCatalogId,
    this.cart = const [],
    this.selectedRoomId,
    this.guestName = '',
    this.source,
    this.note = '',
    this.submitting = false,
  });

  Catalog? get catalog =>
      selectedCatalogId == null ? null : CatalogSeed.byId(selectedCatalogId!);

  bool get hasCart => cart.isNotEmpty;

  int get totalLines => cart.length;

  int get totalUnits =>
      cart.fold<int>(0, (acc, l) => acc + l.quantity);

  double get total =>
      cart.fold<double>(0, (acc, l) => acc + l.lineTotal);

  /// Lines for a given item, ordered by insertion. Used for #N indices.
  List<CartLine> linesFor(String itemId) =>
      cart.where((l) => l.item.id == itemId).toList(growable: false);

  int quantityFor(String itemId) =>
      linesFor(itemId).fold<int>(0, (acc, l) => acc + l.quantity);

  bool get canContinue => hasCart;

  bool get canSubmit =>
      hasCart &&
      selectedRoomId != null &&
      source != null &&
      !submitting;

  CatalogDraftState copyWith({
    CatalogStep? step,
    String? selectedCatalogId,
    bool clearCatalog = false,
    List<CartLine>? cart,
    String? selectedRoomId,
    bool clearRoom = false,
    String? guestName,
    TicketSource? source,
    bool clearSource = false,
    String? note,
    bool? submitting,
  }) {
    return CatalogDraftState(
      step: step ?? this.step,
      selectedCatalogId:
          clearCatalog ? null : (selectedCatalogId ?? this.selectedCatalogId),
      cart: cart ?? this.cart,
      selectedRoomId:
          clearRoom ? null : (selectedRoomId ?? this.selectedRoomId),
      guestName: guestName ?? this.guestName,
      source: clearSource ? null : (source ?? this.source),
      note: note ?? this.note,
      submitting: submitting ?? this.submitting,
    );
  }
}

class CatalogDraftController extends AutoDisposeNotifier<CatalogDraftState> {
  int _lineCounter = 0;

  @override
  CatalogDraftState build() => const CatalogDraftState();

  // ── Navigation ────────────────────────────────────────────────────────────
  void selectCatalog(String id) {
    state = state.copyWith(
      selectedCatalogId: id,
      step: CatalogStep.selectItems,
    );
  }

  void backToCatalogSelect() {
    state = state.copyWith(
      step: CatalogStep.selectCatalog,
      clearCatalog: true,
      cart: const [],
    );
  }

  void goToDetails() {
    if (!state.canContinue) return;
    state = state.copyWith(step: CatalogStep.fillDetails);
  }

  void backToItems() =>
      state = state.copyWith(step: CatalogStep.selectItems);

  // ── Cart ops ──────────────────────────────────────────────────────────────

  /// Add a NEW line. For items without options, this collapses to incrementing
  /// the existing single line. For items with options, always appends.
  void addLine({
    required CatalogItem item,
    int quantity = 1,
    Map<String, Option> selectedOptions = const {},
    Map<String, int> selectedAddOns = const {},
  }) {
    if (!item.hasOptions) {
      // Collapse: same item without options = bump existing line.
      final existingIdx = state.cart.indexWhere((l) => l.item.id == item.id);
      if (existingIdx != -1) {
        final existing = state.cart[existingIdx];
        final next = [...state.cart];
        next[existingIdx] =
            existing.copyWith(quantity: existing.quantity + quantity);
        state = state.copyWith(cart: next);
        return;
      }
    }
    final id = 'line_${++_lineCounter}';
    state = state.copyWith(
      cart: [
        ...state.cart,
        CartLine(
          id: id,
          item: item,
          quantity: quantity,
          selectedOptions: selectedOptions,
          selectedAddOns: selectedAddOns,
        ),
      ],
    );
  }

  void editLine({
    required String lineId,
    int? quantity,
    Map<String, Option>? selectedOptions,
    Map<String, int>? selectedAddOns,
  }) {
    final idx = state.cart.indexWhere((l) => l.id == lineId);
    if (idx == -1) return;
    final next = [...state.cart];
    next[idx] = next[idx].copyWith(
      quantity: quantity,
      selectedOptions: selectedOptions,
      selectedAddOns: selectedAddOns,
    );
    state = state.copyWith(cart: next);
  }

  void removeLine(String lineId) {
    state = state.copyWith(
      cart: state.cart.where((l) => l.id != lineId).toList(growable: false),
    );
  }

  /// Inline stepper — used by no-options items in the menu list.
  void setItemQuantity(CatalogItem item, int qty) {
    if (item.hasOptions) return;
    final clamped = qty.clamp(0, 99);
    final idx = state.cart.indexWhere((l) => l.item.id == item.id);
    if (clamped == 0) {
      if (idx == -1) return;
      removeLine(state.cart[idx].id);
      return;
    }
    if (idx == -1) {
      addLine(item: item, quantity: clamped);
      return;
    }
    final next = [...state.cart];
    next[idx] = next[idx].copyWith(quantity: clamped);
    state = state.copyWith(cart: next);
  }

  void clearCart() => state = state.copyWith(cart: const []);

  // ── Form fields ───────────────────────────────────────────────────────────
  void selectRoom(String roomId) =>
      state = state.copyWith(selectedRoomId: roomId);
  void clearRoom() => state = state.copyWith(clearRoom: true);
  void setGuestName(String v) => state = state.copyWith(guestName: v);
  void setSource(TicketSource s) => state = state.copyWith(source: s);
  void setNote(String v) => state = state.copyWith(note: v);

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(submitting: true);
    try {
      final repo = ref.read(ticketsRepositoryProvider);
      final ticket = await repo.create(_buildDraft());
      return ticket.id;
    } finally {
      if (ref.exists(catalogDraftControllerProvider)) {
        state = state.copyWith(submitting: false);
      }
    }
  }

  NewTicketDraft _buildDraft() {
    final catalog = state.catalog!;
    final lines = state.cart;

    // Build #N indices per item id (only meaningful for items with options).
    final perItemIndex = <String, int>{};
    final items = <RequestItem>[];
    for (final l in lines) {
      final n = (perItemIndex[l.item.id] ?? 0) + 1;
      perItemIndex[l.item.id] = n;
      items.add(
        RequestItem(
          id: l.id,
          title: l.item.name,
          subtitle: catalog.name,
          quantity: l.quantity,
          unitPrice: l.unitPrice,
          lineTotal: l.lineTotal,
          optionsSummary:
              l.optionsSummary.isEmpty ? null : l.optionsSummary,
          lineIndex: l.item.hasOptions ? n : null,
          emoji: l.item.emoji,
        ),
      );
    }

    final title = lines.length == 1
        ? '${lines.first.item.name}${lines.first.quantity > 1 ? ' (${lines.first.quantity})' : ''}'
        : '${catalog.name} order';

    final guest = state.guestName.trim();
    return NewTicketDraft(
      title: title,
      kind: TicketKind.catalog,
      department: catalog.department,
      roomId: state.selectedRoomId!,
      items: items,
      note: state.note.trim().isEmpty ? null : state.note.trim(),
      source: state.source,
      guestName: guest.isEmpty ? null : guest,
      catalogId: catalog.id,
      catalogName: catalog.name,
      total: state.total,
    );
  }
}

final catalogDraftControllerProvider = AutoDisposeNotifierProvider<
    CatalogDraftController, CatalogDraftState>(
  CatalogDraftController.new,
);

/// Catalog list (mock today, swap with API later).
final catalogsProvider = Provider<List<Catalog>>((ref) => CatalogSeed.all());
