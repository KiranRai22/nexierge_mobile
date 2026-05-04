import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A monotonically-increasing tick that bumps once per hour and on every
/// app-resume. Filter providers that bucket tickets by `now` (e.g. the
/// Schedule → Today auto-promote) `ref.watch` this so they recompute when
/// the date boundary may have shifted, without requiring a backend refetch.
class TicketsScheduleClockNotifier extends Notifier<int> {
  Timer? _timer;
  _LifecycleObserver? _observer;

  @override
  int build() {
    _observer = _LifecycleObserver(_bump);
    WidgetsBinding.instance.addObserver(_observer!);
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _bump());
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      if (_observer != null) {
        WidgetsBinding.instance.removeObserver(_observer!);
        _observer = null;
      }
    });
    return 0;
  }

  void _bump() {
    state = state + 1;
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _LifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

final ticketsScheduleClockProvider =
    NotifierProvider<TicketsScheduleClockNotifier, int>(
  TicketsScheduleClockNotifier.new,
);
