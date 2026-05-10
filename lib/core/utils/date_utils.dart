import 'package:intl/intl.dart';

import '../time/server_clock.dart';

/// Comprehensive date/time utilities for consistent formatting
/// and epoch time conversions throughout the application.
abstract class AppDateUtils {
  /// Bucket [when] relative to [now] into `today` / `yesterday` / `older`.
  static DayBucket bucket(DateTime when, {DateTime? now}) {
    final reference = now ?? ServerClock.now();
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
    final reference = now ?? ServerClock.now();
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
    final reference = now ?? ServerClock.now();
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
  static String clock(DateTime when) => DateFormat('h:mm a').format(when);

  /// Convert milliseconds since epoch to relative time ago string.
  /// Handles both seconds and milliseconds timestamps automatically.
  static String timeAgo(int millisecondsSinceEpoch) {
    // Auto-detect if timestamp is in seconds (10 digits) or milliseconds (13 digits)
    final ms = millisecondsSinceEpoch.toString().length <= 10
        ? millisecondsSinceEpoch * 1000
        : millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return relative(dt);
  }

  /// Convert milliseconds to formatted date string.
  /// Format: `Jan 15, 2024, 2:30 PM`
  static String formatMillis(int millisecondsSinceEpoch) {
    final ms = millisecondsSinceEpoch.toString().length <= 10
        ? millisecondsSinceEpoch * 1000
        : millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('MMM d, yyyy, h:mm a').format(dt);
  }

  // ---------------------------------------------------------------------------
  // Epoch Time Conversions
  // ---------------------------------------------------------------------------

  /// Auto-detects timestamp format (seconds vs milliseconds) and converts to DateTime
  static DateTime fromEpoch(dynamic timestamp) {
    int ms;

    if (timestamp is String) {
      final intTimestamp = int.tryParse(timestamp) ?? 0;
      ms = intTimestamp.toString().length <= 10
          ? intTimestamp * 1000
          : intTimestamp;
    } else if (timestamp is int) {
      ms = timestamp.toString().length <= 10 ? timestamp * 1000 : timestamp;
    } else {
      throw ArgumentError('Timestamp must be int or String');
    }

    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Convert DateTime to epoch milliseconds
  static int toEpochMillis(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// Convert DateTime to epoch seconds
  static int toEpochSeconds(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }

  /// Get current epoch milliseconds
  static int currentEpochMillis() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Get current epoch seconds
  static int currentEpochSeconds() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// Convert epoch milliseconds to epoch seconds
  static int millisToSeconds(int milliseconds) {
    return milliseconds ~/ 1000;
  }

  /// Convert epoch seconds to epoch milliseconds
  static int secondsToMillis(int seconds) {
    return seconds * 1000;
  }

  // ---------------------------------------------------------------------------
  // Comprehensive Date Formatting
  // ---------------------------------------------------------------------------

  /// Format DateTime with custom pattern
  static String format(DateTime dateTime, String pattern) {
    return DateFormat(pattern).format(dateTime);
  }

  /// Format with ISO 8601 standard
  static String toIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parse ISO 8601 string to DateTime
  static DateTime fromIso8601(String isoString) {
    return DateTime.parse(isoString);
  }

  /// Format: `2024-01-15`
  static String toYYYYMMDD(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Format: `15/01/2024`
  static String toDDMMYYYY(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  /// Format: `01/15/2024`
  static String toMMDDYYYY(DateTime dateTime) {
    return DateFormat('MM/dd/yyyy').format(dateTime);
  }

  /// Format: `15-Jan-2024`
  static String toDDMonYYYY(DateTime dateTime) {
    return DateFormat('dd-MMM-yyyy').format(dateTime);
  }

  /// Format: `Jan 15, 2024`
  static String toMonDDYYYY(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  /// Format: `January 15, 2024`
  static String toFullMonthDDYYYY(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  /// Format: `2024-01-15 14:30:00`
  static String toYYYYMMDDHHMMSS(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Format: `15/01/2024 14:30`
  static String toDDMMYYYYHHMM(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Format: `2:30 PM`
  static String toHHMMA(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format: `14:30`
  static String toHHMM24(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format: `14:30:45`
  static String toHHMMSS24(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  /// Format: `Monday, January 15, 2024`
  static String toFullDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d, yyyy').format(dateTime);
  }

  /// Format: `Mon, 15 Jan 2024 14:30:00 GMT`
  static String toRFC2822(DateTime dateTime) {
    return DateFormat('EEE, d MMM yyyy HH:mm:ss Z').format(dateTime);
  }

  // ---------------------------------------------------------------------------
  // Time Zone Utilities
  // ---------------------------------------------------------------------------

  /// Convert DateTime to UTC epoch milliseconds
  static int toUtcEpochMillis(DateTime dateTime) {
    return dateTime.toUtc().millisecondsSinceEpoch;
  }

  /// Convert DateTime to UTC epoch seconds
  static int toUtcEpochSeconds(DateTime dateTime) {
    return dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  /// Convert UTC epoch milliseconds to local DateTime
  static DateTime fromUtcEpochMillis(int milliseconds) {
    return DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: true,
    ).toLocal();
  }

  /// Convert UTC epoch seconds to local DateTime
  static DateTime fromUtcEpochSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal();
  }

  // ---------------------------------------------------------------------------
  // Date Arithmetic
  // ---------------------------------------------------------------------------

  /// Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtract days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Add hours to date
  static DateTime addHours(DateTime date, int hours) {
    return date.add(Duration(hours: hours));
  }

  /// Add minutes to date
  static DateTime addMinutes(DateTime date, int minutes) {
    return date.add(Duration(minutes: minutes));
  }

  /// Get start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    return subtractDays(date, daysToSubtract);
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysToAdd = DateTime.sunday - date.weekday;
    return addDays(date, daysToAdd);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  // ---------------------------------------------------------------------------
  // Validation and Comparison
  // ---------------------------------------------------------------------------

  /// Check if date is today
  static bool isToday(DateTime date) {
    return bucket(date) == DayBucket.today;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    return bucket(date) == DayBucket.yesterday;
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date, {DateTime? reference}) {
    final now = reference ?? ServerClock.now();
    return date.isAfter(now);
  }

  /// Check if date is in the past
  static bool isPast(DateTime date, {DateTime? reference}) {
    final now = reference ?? ServerClock.now();
    return date.isBefore(now);
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// Get hours between two dates
  static int hoursBetween(DateTime start, DateTime end) {
    return end.difference(start).inHours;
  }

  /// Get minutes between two dates
  static int minutesBetween(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }
}

enum DayBucket { today, yesterday, older }
