import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has dismissed the one-time swipe-coach banner
/// shown above the unread notifications list.
///
/// State is `true` when the banner should remain hidden (already dismissed),
/// `false` when it should be shown. Defaults to `false` until the persisted
/// value loads so first-time users see the coach.
final swipeCoachDismissedProvider =
    StateNotifierProvider<SwipeCoachNotifier, bool>(
      (ref) => SwipeCoachNotifier(),
    );

class SwipeCoachNotifier extends StateNotifier<bool> {
  static const String _key = 'notifications.swipeCoach.dismissed';

  SwipeCoachNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (_) {
      state = false;
    }
  }

  Future<void> dismiss() async {
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Keep the in-memory dismissal for this session even if persistence
      // fails — the banner will reappear next launch, which is acceptable.
    }
  }
}
