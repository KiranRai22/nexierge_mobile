import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/ticket_change_event.dart';

/// Process-wide broadcast bus for [TicketChangeEvent]s. The realtime layer
/// publishes here whenever a ticket is created or its status moves. Consumers
/// (toast + sound dispatcher, future analytics) subscribe via
/// [ticketEventStreamProvider].
class TicketEventBus {
  TicketEventBus._();

  static final TicketEventBus _instance = TicketEventBus._();
  static TicketEventBus get instance => _instance;

  final StreamController<TicketChangeEvent> _ctrl =
      StreamController<TicketChangeEvent>.broadcast();

  Stream<TicketChangeEvent> get stream => _ctrl.stream;

  void emit(TicketChangeEvent event) {
    if (!_ctrl.isClosed) _ctrl.add(event);
  }
}

/// Riverpod accessor for the ticket event stream.
final ticketEventStreamProvider = StreamProvider<TicketChangeEvent>((ref) {
  return TicketEventBus.instance.stream;
});
