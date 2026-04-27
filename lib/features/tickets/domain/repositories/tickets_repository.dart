import '../models/department.dart';
import '../models/ticket.dart';

/// Inputs needed to draft a new ticket. Kept minimal — the repository fills
/// in id, code, timestamps, status.
class NewTicketDraft {
  final String title;
  final TicketKind kind;
  final Department department;
  final String roomId;
  final List<RequestItem> items;
  final String? note;

  const NewTicketDraft({
    required this.title,
    required this.kind,
    required this.department,
    required this.roomId,
    required this.items,
    this.note,
  });
}

/// Repository contract for tickets. Implementations:
/// - `MockTicketsRepository` (in-memory, used today)
/// - `RemoteTicketsRepository` (Phase 7 — http + websocket)
///
/// UI screens MUST go through this interface; never the data layer directly.
abstract class TicketsRepository {
  /// Reactive stream of every ticket — list reorders, status changes, new
  /// tickets all flow through here. Sorted desc by [Ticket.createdAt].
  Stream<List<Ticket>> watchAll();

  /// Single-ticket stream used by the detail screen.
  Stream<Ticket?> watch(String id);

  /// Snapshot (no stream).
  List<Ticket> snapshot();

  /// Available rooms across the hotel (also used by Universal create).
  List<Room> rooms();

  /// Mutations.
  Future<Ticket> create(NewTicketDraft draft);
  Future<void> accept(String id, {required Duration etaIn});
  Future<void> markDone(String id);
  Future<void> cancel(String id);
  Future<void> changeDepartment(String id, Department newDept);
  Future<void> addNote(String id, String note);
  Future<void> remove(String id); // only used by undo
}
