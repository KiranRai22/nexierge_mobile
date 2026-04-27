import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activity/domain/repositories/activity_repository.dart';
import '../../data/repositories/mock_tickets_repository.dart';
import '../../domain/repositories/tickets_repository.dart';

/// Single instance of the in-memory store. Kept alive for the lifetime of
/// the app so writes from create flow propagate to all listeners (lists,
/// detail, activity feed). When the real backend lands, swap the body of
/// these two providers — UI code stays untouched.
final _mockStore = MockTicketsRepository();

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  return _mockStore;
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return _mockStore;
});
