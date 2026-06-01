import 'package:flutter/foundation.dart';

import '../../../tickets/domain/entities/checked_in_guest_stay.dart';

/// Result of validating whether a time extension is allowed for a ticket
/// given the associated guest's checkout constraints.
class AddTimeValidation {
  /// Whether the selected [extensionMinutes] is permitted.
  final bool allowed;

  /// Human-readable reason when [allowed] is false. Null when allowed.
  final String? blockedReason;

  /// The resolved checkout deadline (local). Null when no stay was found.
  final DateTime? checkoutDeadline;

  /// Minutes remaining between `(now + 15 min)` and [checkoutDeadline].
  ///
  /// Positive  → checkout is still in the future relative to the minimum
  ///             add-time window.
  /// Zero/neg  → the minimum 15-min window already exceeds checkout.
  /// Null      → no stay / no checkout date found.
  final int? minutesUntilCheckout;

  const AddTimeValidation._({
    required this.allowed,
    this.blockedReason,
    this.checkoutDeadline,
    this.minutesUntilCheckout,
  });

  factory AddTimeValidation.allowed({
    DateTime? checkoutDeadline,
    int? minutesUntilCheckout,
  }) => AddTimeValidation._(
        allowed: true,
        checkoutDeadline: checkoutDeadline,
        minutesUntilCheckout: minutesUntilCheckout,
      );

  factory AddTimeValidation.blocked({
    required String reason,
    DateTime? checkoutDeadline,
    int? minutesUntilCheckout,
  }) => AddTimeValidation._(
        allowed: false,
        blockedReason: reason,
        checkoutDeadline: checkoutDeadline,
        minutesUntilCheckout: minutesUntilCheckout,
      );

  /// Returns true if a chip with [chipMinutes] should be shown.
  ///
  /// A chip is hidden when adding that many minutes from `now + 15 min`
  /// would exceed the checkout deadline. That is, the chip is only shown
  /// when `chipMinutes <= minutesUntilCheckout`.
  ///
  /// When there is no checkout constraint (minutesUntilCheckout is null),
  /// all chips are shown.
  bool chipVisible(int chipMinutes) {
    final budget = minutesUntilCheckout;
    if (budget == null) return true;
    return chipMinutes <= budget;
  }
}

/// Evaluates whether adding [extensionMinutes] to the base due time is
/// permitted given the guest's checkout constraints.
///
/// [baseDueAtMs] is the effective due-time base:
///   • ticket.eta when set
///   • DateTime.now() otherwise
///
/// Logic:
///   1. If no matching stay → allowed, no cap.
///   2. If checkout date unparseable → allowed, no cap.
///   3. If guest is not active (already checked out) → blocked.
///   4. Compute `minutesUntilCheckout` = checkout − (now + 15 min), in
///      minutes. This is the budget for ALL chips.
///   5. If `extensionMinutes > minutesUntilCheckout` → blocked.
///   6. Otherwise → allowed.
AddTimeValidation validateAddTime({
  required int baseDueAtMs,
  required int extensionMinutes,
  required CheckedInGuestStay? stay,
}) {
  if (stay == null) {
    //debugPrint('[AddTimeValidation] stay=null → no constraint, ALLOWED');
    return AddTimeValidation.allowed();
  }

  //debugPrint(
  //   '[AddTimeValidation] stay found: ${stay.fullName} room=${stay.roomId} '
  //   'status="${stay.status}" checkoutDate="${stay.checkoutDate}"',
  // );

  final checkoutDt = _parseCheckoutDate(stay.checkoutDate);
  if (checkoutDt == null) {
    //debugPrint(
    //   '[AddTimeValidation] checkoutDate="${stay.checkoutDate}" could not '
    //   'be parsed → no constraint, ALLOWED',
    // );
    return AddTimeValidation.allowed();
  }

  //debugPrint('[AddTimeValidation] parsed checkoutDt=$checkoutDt');

  final statusLower = stay.status.toLowerCase();
  final isActive =
      statusLower == 'checked_in' ||
      statusLower == 'staying' ||
      statusLower == 'active' ||
      statusLower == 'currently staying';

  //debugPrint(
  //   '[AddTimeValidation] statusLower="$statusLower" isActive=$isActive',
  // );

  if (!isActive) {
    //debugPrint('[AddTimeValidation] BLOCKED — guest not active');
    return AddTimeValidation.blocked(
      reason: _blockedMessage(stay),
      checkoutDeadline: checkoutDt,
    );
  }

  // Anchor: now + 15 min (the minimum add-time window).
  final now = DateTime.now();
  final anchor = now.add(const Duration(minutes: 15));

  // Budget = how many minutes are left between the minimum anchor and checkout.
  final minutesUntilCheckout = checkoutDt.difference(anchor).inMinutes;

  final hoursLeft = minutesUntilCheckout / 60;
  //debugPrint(
  //   '\n╔══════════════════════════════════════════════════════\n'
  //   '║  [AddTimeValidation] Checkout Budget Check\n'
  //   '╠══════════════════════════════════════════════════════\n'
  //   '║  Guest         : ${stay.fullName} (Room #${stay.roomNumber})\n'
  //   '║  Status        : ${stay.status}\n'
  //   '║  Checkout date : $checkoutDt\n'
  //   '╠──────────────────────────────────────────────────────\n'
  //   '║  Current time  : $now\n'
  //   '║  Anchor (+15m) : $anchor\n'
  //   '╠──────────────────────────────────────────────────────\n'
  //   '║  Budget (checkout − anchor)\n'
  //   '║    = $minutesUntilCheckout min  (≈ ${hoursLeft.toStringAsFixed(1)} hrs)\n'
  //   '║  Requested ext : $extensionMinutes min\n'
  //   '╠──────────────────────────────────────────────────────\n'
  //   '║  Decision      : ${minutesUntilCheckout < 0 ? "BLOCKED — even +15 min exceeds checkout" : extensionMinutes > minutesUntilCheckout ? "BLOCKED — $extensionMinutes min > budget $minutesUntilCheckout min" : "ALLOWED — $extensionMinutes min ≤ budget $minutesUntilCheckout min"}\n'
  //   '╚══════════════════════════════════════════════════════',
  // );

  if (minutesUntilCheckout < 0) {
    // Even the minimum 15-min window exceeds checkout — nothing allowed.
    return AddTimeValidation.blocked(
      reason: _blockedMessage(stay),
      checkoutDeadline: checkoutDt,
      minutesUntilCheckout: minutesUntilCheckout,
    );
  }

  if (extensionMinutes > minutesUntilCheckout) {
    return AddTimeValidation.blocked(
      reason: _blockedMessage(stay),
      checkoutDeadline: checkoutDt,
      minutesUntilCheckout: minutesUntilCheckout,
    );
  }

  return AddTimeValidation.allowed(
    checkoutDeadline: checkoutDt,
    minutesUntilCheckout: minutesUntilCheckout,
  );
}

/// Builds the standardised blocked-reason message shown in the sheet.
String _blockedMessage(CheckedInGuestStay stay) =>
    'You cannot increase the resolution time for this ticket since '
    'Customer: ${stay.fullName.isNotEmpty ? stay.fullName : 'Guest'} '
    'on Room No: #${stay.roomNumber} is checking out. '
    'Connect with your supervisor for further details. Thank You';

/// Attempts to parse the checkout date string into a [DateTime].
///
/// Handles common formats returned by the API:
///   • ISO-8601 full datetime:  "2026-06-03T10:00:00.000Z"
///   • Date-only (no time):     "2026-06-03" → treated as midnight (00:00)
///                               on that local date.
///   • Unix ms as string:       "1748908800000"
///
/// Returns null when the string is empty or unrecognisable.
DateTime? _parseCheckoutDate(String raw) {
  if (raw.isEmpty) return null;

  // Check if it is a date-only string (no 'T' separator, no time component).
  // e.g. "2026-06-03" — treat as midnight LOCAL time on that day.
  final isDateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw.trim());
  if (isDateOnly) {
    final parts = raw.trim().split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      0, 0, 0,
    );
  }

  // Full ISO-8601 datetime (UTC or offset — DateTime.parse handles both).
  try {
    return DateTime.parse(raw).toLocal();
  } catch (_) {}

  // Unix milliseconds stored as a string.
  final ms = int.tryParse(raw);
  if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();

  return null;
}
