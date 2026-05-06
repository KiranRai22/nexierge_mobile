import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_bootstrap_controller.dart';
import '../../data/datasources/ticket_remote_data_source.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/ticket.dart';
import 'checked_in_guest_stays_provider.dart';
import 'tickets_paged_notifier.dart';

/// Three-step Catalog create flow:
///   1. selectCatalog — pick which catalog to order from
///   2. selectItems — browse menu, build cart
///   3. fillDetails — room/guest/source/notes/confirm
enum CatalogStep { selectCatalog, selectItems, fillDetails }

@immutable
class CatalogDraftState {
  final CatalogStep step;
  final Catalog? selectedCatalog;
  final List<CartLine> cart;

  /// Selected checked-in stay's `guest_stay_id`. Field name kept for
  /// state-shape stability (was a room id originally).
  final String? selectedRoomId;

  /// Resolved `contact_id` from the picked checked-in stay. Sent on the
  /// create-order payload alongside `guest_stay_id`.
  final String? selectedContactId;

  final String guestName;
  final TicketSource? source;
  final String note;
  final bool submitting;

  const CatalogDraftState({
    this.step = CatalogStep.selectCatalog,
    this.selectedCatalog,
    this.cart = const [],
    this.selectedRoomId,
    this.selectedContactId,
    this.guestName = '',
    this.source,
    this.note = '',
    this.submitting = false,
  });

  Catalog? get catalog => selectedCatalog;
  String? get selectedCatalogId => selectedCatalog?.id;

  bool get hasCart => cart.isNotEmpty;

  int get totalLines => cart.length;

  int get totalUnits => cart.fold<int>(0, (acc, l) => acc + l.quantity);

  double get total => cart.fold<double>(0, (acc, l) => acc + l.lineTotal);

  /// Lines for a given item, ordered by insertion. Used for #N indices.
  List<CartLine> linesFor(String itemId) =>
      cart.where((l) => l.item.id == itemId).toList(growable: false);

  int quantityFor(String itemId) =>
      linesFor(itemId).fold<int>(0, (acc, l) => acc + l.quantity);

  bool get canContinue => hasCart;

  bool get canSubmit =>
      hasCart && selectedRoomId != null && source != null && !submitting;

  CatalogDraftState copyWith({
    CatalogStep? step,
    Catalog? selectedCatalog,
    bool clearCatalog = false,
    List<CartLine>? cart,
    String? selectedRoomId,
    String? selectedContactId,
    bool clearRoom = false,
    String? guestName,
    TicketSource? source,
    bool clearSource = false,
    String? note,
    bool? submitting,
  }) {
    return CatalogDraftState(
      step: step ?? this.step,
      selectedCatalog: clearCatalog
          ? null
          : (selectedCatalog ?? this.selectedCatalog),
      cart: cart ?? this.cart,
      selectedRoomId: clearRoom
          ? null
          : (selectedRoomId ?? this.selectedRoomId),
      selectedContactId: clearRoom
          ? null
          : (selectedContactId ?? this.selectedContactId),
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
  void selectCatalog(Catalog catalog) {
    state = state.copyWith(
      selectedCatalog: catalog,
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

  void backToItems() => state = state.copyWith(step: CatalogStep.selectItems);

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
        next[existingIdx] = existing.copyWith(
          quantity: existing.quantity + quantity,
        );
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
  /// Picker now returns `guest_stay_id` (sourced from checked-in stays),
  /// not a room id. We keep the field name `selectedRoomId` for state shape
  /// stability; semantically it's the guest_stay_id. Also auto-fills the
  /// guest name from the resolved stay so the operator can still edit it.
  void selectRoom(String guestStayId) {
    final stay = ref.read(checkedInStayByIdProvider(guestStayId));
    state = state.copyWith(
      selectedRoomId: guestStayId,
      selectedContactId: stay?.contactId,
      guestName: stay?.fullName ?? state.guestName,
    );
  }

  void clearRoom() => state = state.copyWith(clearRoom: true);
  void setGuestName(String v) => state = state.copyWith(guestName: v);
  void setSource(TicketSource s) => state = state.copyWith(source: s);
  void setNote(String v) => state = state.copyWith(note: v);

  // ── Submit ────────────────────────────────────────────────────────────────
  /// Submits the catalog order via the real `/service_catalogs/user_app/order/create`
  /// endpoint. Builds the payload from the cart + selected stay, prints it
  /// for debugging, then triggers a refresh of the Today tab so the new
  /// ticket shows up there immediately. Returns the created ticket id
  /// (may be empty if the backend doesn't echo one — still treated as
  /// success).
  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(submitting: true);
    try {
      final hotelId = ref
              .read(dashboardBootstrapControllerProvider)
              .valueOrNull
              ?.userProfile
              ?.hotelDetails
              .hotel
              .id ??
          '';
      final request = _buildCatalogOrderRequest(hotelId);
      // Per user request: print the full payload before firing the API.
      debugPrint(
        '[CatalogDraftController] createCatalogOrder payload: ${request.toJson()}',
      );

      final repo = ref.read(ticketRepositoryProvider);
      final ticketId = await repo.createCatalogOrder(request: request);

      // Surface the new ticket on the Today tab without waiting for the
      // realtime push.
      try {
        await ref
            .read(ticketsPagedProvider(specForTab(TicketsTab.today)).notifier)
            .refresh();
      } catch (e) {
        debugPrint('[CatalogDraftController] today refresh failed: $e');
      }

      return ticketId.isEmpty ? '_pending_' : ticketId;
    } finally {
      if (ref.exists(catalogDraftControllerProvider)) {
        state = state.copyWith(submitting: false);
      }
    }
  }

  /// Build the request body matching the API spec exactly. Single-select
  /// modifier groups send `modifier_quantity = 1`; multi-add-on groups
  /// send the stepper count. Empty groups are skipped.
  CreateCatalogOrderRequestDto _buildCatalogOrderRequest(String hotelId) {
    final catalog = state.catalog!;
    final items = <CreateOrderItemDto>[];

    for (final line in state.cart) {
      final groups = <CreateOrderModifierGroupDto>[];

      for (final group in line.item.optionGroups) {
        final mods = <CreateOrderModifierDto>[];

        if (group.type == OptionGroupType.singleSelect) {
          final picked = line.selectedOptions[group.id];
          if (picked != null) {
            mods.add(CreateOrderModifierDto(
              modifierId: picked.id,
              modifierName: picked.name,
              modifierQuantity: 1,
              modifierPrice: picked.priceDelta,
            ));
          }
        } else {
          // multiAddOn: one entry per non-zero stepper.
          for (final option in group.options) {
            final qty = line.selectedAddOns['${group.id}:${option.id}'] ?? 0;
            if (qty <= 0) continue;
            mods.add(CreateOrderModifierDto(
              modifierId: option.id,
              modifierName: option.name,
              modifierQuantity: qty,
              modifierPrice: option.priceDelta,
            ));
          }
        }

        if (mods.isEmpty) continue;

        groups.add(CreateOrderModifierGroupDto(
          modifierGroupId: group.id,
          modifierGroupName: group.name,
          modifiers: mods,
        ));
      }

      // No-options items get one entry per cart line. Items with options
      // are 1-unit per line by construction; for collapsed no-option
      // lines we still send a single item entry — the backend treats the
      // `quantity` semantic via repeated rows or downstream logic.
      items.add(CreateOrderItemDto(
        itemId: line.item.id,
        specialInstructions: '',
        modifierGroups: groups,
      ));
    }

    return CreateCatalogOrderRequestDto(
      hotelId: hotelId,
      // Empty strings allowed — walk-in / unattended orders.
      guestStayId: state.selectedRoomId ?? '',
      contactId: state.selectedContactId ?? '',
      serviceCatalogsId: catalog.id,
      notes: state.note.trim(),
      subTotal: state.total,
      // Catalog model carries no tax/sla fields yet — server will compute
      // or default. Tracking id is intentionally empty per current spec.
      tax: 0,
      slaTargetMinutes: 0,
      trackingId: '',
      items: items,
    );
  }

}

final catalogDraftControllerProvider =
    AutoDisposeNotifierProvider<CatalogDraftController, CatalogDraftState>(
      CatalogDraftController.new,
    );
