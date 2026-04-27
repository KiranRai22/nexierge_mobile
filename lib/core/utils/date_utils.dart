import 'package:intl/intl.dart';

/// Pure date helpers used across the app — bucketing and short relative
/// formatting compatible with the HotelOps prototype.
abstract class AppDateUtils {
  /// Bucket [when] relative to [now] into `today` / `yesterday` / `older`.
  static DayBucket bucket(DateTime when, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final whenDay = DateTime(when.year, when.month, when.day);
    final today = DateTime(reference.year, reference.month, reference.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (whenDay == today) return DayBucket.today;
    if (whenDay == yesterday) return DayBucket.yesterday;
    return DayBucket.older;
  }

  /// Compact relative time used in lists and cards: `Just now`, `2m ago`,
  /// `11m ago`, `3h ago`, `2d ago`. Anything older falls back to a short date
  /// like `Apr 12`.
  static String relative(DateTime when, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final delta = reference.difference(when);
    if (delta.inSeconds < 30) return 'Just now';
    if (delta.inMinutes < 1) return '${delta.inSeconds}s ago';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return DateFormat('MMM d').format(when);
  }

  /// Short ETA-in-N-minutes label used inside cards (`ETA 3m`, `ETA 1h`).
  static String etaShort(DateTime eta, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final delta = eta.difference(reference);
    if (delta.isNegative) return 'Now';
    if (delta.inMinutes < 60) return 'ETA ${delta.inMinutes}m';
    final hours = delta.inMinutes ~/ 60;
    return 'ETA ${hours}h';
  }

  /// Day-of-week + short time, e.g. `SUN · 1:00 AM`. Used in greeting row.
  static String shortDayTime(DateTime when) {
    final day = DateFormat('EEE').format(when).toUpperCase();
    final time = DateFormat('h:mm a').format(when);
    return '$day · $time';
  }

  /// Long timestamp inside the timing stepper, e.g. `4 minutes ago · 10:24`.
  static String timingLine(DateTime when, {DateTime? now}) {
    final time = DateFormat('H:mm').format(when);
    return '${relative(when, now: now)} · $time';
  }

  /// Short clock used by the ETA sheet `Ready by 1:40 AM` line.
  static String clock(DateTime when) =>
      DateFormat('h:mm a').format(when);
}

enum DayBucket { today, yesterday, older }
