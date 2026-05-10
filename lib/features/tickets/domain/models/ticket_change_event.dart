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

  /// Best-effort user-facing label for the ticket (room number, code, or
  /// guest name). Used by the toast subtitle. Empty string when unknown.
  final String label;

  const TicketChangeEvent({
    required this.ticketId,
    required this.kind,
    required this.at,
    required this.label,
    this.oldStatus,
    this.newStatus,
  });
}
