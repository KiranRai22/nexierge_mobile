import '../models/activity_event.dart';

/// Repository for the activity feed. Today's mock impl listens to ticket
/// lifecycle changes and synthesises events. Real impl will subscribe to a
/// server-side feed.
abstract class ActivityRepository {
  /// Reactive stream of all events ordered desc by [ActivityEvent.at].
  ///
  /// Named `watchEvents` (not `watchAll`) so the same concrete class can also
  /// implement [TicketsRepository] without a method-name collision.
  Stream<List<ActivityEvent>> watchEvents();

  /// Snapshot (no stream).
  List<ActivityEvent> eventsSnapshot();
}
