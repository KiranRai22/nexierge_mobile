/// Kind of change observed on a ticket via realtime.
enum TicketChangeKind {
  /// Ticket id was not in our local state — a brand new ticket arrived.
  created,

  /// Ticket id was already known, and its status moved.
  statusChanged,

  /// Ticket id was removed.
  deleted,
}

/// One observed change to a ticket. Emitted onto [ticketEventBusProvider]
/// every time the realtime layer mutates ticket state. Consumers (toast +
/// sound dispatcher, analytics) listen and react.
class TicketChangeEvent {
  final String ticketId;
  final TicketChangeKind kind;
  final DateTime at;

  /// Status before the change. Null for [TicketChangeKind.created].
  final String? oldStatus;

  /// Status after the change. Null for [TicketChangeKind.deleted].
  final String? newStatus;

  /// Best-effort user-facing label for the ticket (issue summary / title,
  /// falling back to room number). Used by the toast subtitle. Empty string when unknown.
  final String label;

  /// Ticket type (MANUAL / CATALOG / UNIVERSAL — server-side `type` field).
  /// Empty string when unknown. Drives the "Type: …" line in toast.
  final String ticketKind;

  /// Due-at epoch in milliseconds. `0` when the ticket has no due time
  /// (or the field wasn't sent by the server). Drives the "Due: …" line.
  final int dueAt;

  const TicketChangeEvent({
    required this.ticketId,
    required this.kind,
    required this.at,
    required this.label,
    this.oldStatus,
    this.newStatus,
    this.ticketKind = '',
    this.dueAt = 0,
  });
}
