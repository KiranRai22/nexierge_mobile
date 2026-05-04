import 'package:flutter/foundation.dart';

/// One currently-staying guest returned by `/guest_stay/checked_in`.
///
/// Flattens the nested `room_details` and `contact_details` so callers
/// don't have to dig. Top-level `room_number` is a UUID alias for the
/// room id and is intentionally NOT exposed — use [roomNumber] (display)
/// and [roomId] instead.
@immutable
class CheckedInGuestStay {
  /// `id` on the API row — used as `guest_stay_id` on ticket payloads.
  final String guestStayId;

  /// `room_details.id` — the canonical room UUID.
  final String roomId;

  /// `room_details.onb_room_number` — what the user sees ("8", "34", "1A").
  final String roomNumber;

  /// `contact_id` — primary contact only. Secondary contacts are kept as-is
  /// in [secondaryContacts] in case a future flow needs them.
  final String contactId;

  /// `contact_details.full_name` — pre-built display name.
  final String fullName;

  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? countryCode;

  final String status;
  final String checkinDate;
  final String checkoutDate;

  final String? roomTypeId;

  /// Pass-through for future use; nullable + may be empty list.
  final List<dynamic>? secondaryContacts;

  const CheckedInGuestStay({
    required this.guestStayId,
    required this.roomId,
    required this.roomNumber,
    required this.contactId,
    required this.fullName,
    required this.status,
    required this.checkinDate,
    required this.checkoutDate,
    this.firstName,
    this.lastName,
    this.languageCode,
    this.countryCode,
    this.roomTypeId,
    this.secondaryContacts,
  });
}
