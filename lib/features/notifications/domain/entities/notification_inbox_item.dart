/// Kind of inbox notification — drives icon + color treatment.
///
/// Today there's only one variant (new ticket received) which is what the
/// Lovable prototype ships. Keep this an enum so future variants
/// (assignment, ETA breach, etc.) plug in without touching call sites.
enum NotificationInboxKind { newTicket }

/// Single row inside the notifications bottom sheet. Pure UI model — the
/// data layer maps backend payloads / FCM messages into this shape so the
/// presentation layer never sees raw transport types.
class NotificationInboxItem {
  final String id;
  final NotificationInboxKind kind;

  /// Localised title (e.g. "New ticket received"). Sourced from l10n at
  /// the call site so the entity stays locale-agnostic when persisted.
  final String title;

  /// Free-form subtitle (e.g. "Extra towels · Room 208 · Housekeeping").
  /// Domain doesn't try to parse the parts — the prototype renders the
  /// concatenated string verbatim.
  final String subtitle;

  /// When the event happened. Used to compute the "7h ago" pill.
  final DateTime receivedAt;

  /// Whether the user has not yet seen this row. Drives the trailing
  /// purple dot and the unread count in the header.
  final bool unread;

  /// Optional deep-link payload — `null` for non-ticket variants.
  final String? ticketId;

  const NotificationInboxItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.receivedAt,
    required this.unread,
    this.ticketId,
  });

  NotificationInboxItem copyWith({bool? unread}) {
    return NotificationInboxItem(
      id: id,
      kind: kind,
      title: title,
      subtitle: subtitle,
      receivedAt: receivedAt,
      unread: unread ?? this.unread,
      ticketId: ticketId,
    );
  }
}
