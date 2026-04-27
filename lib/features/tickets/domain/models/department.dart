import '../../../../l10n/generated/app_localizations.dart';

/// Hotel department a ticket can be routed to. Stable enum so Activity
/// events and create flows can reference the same identity.
///
/// Display labels are resolved through [label] using the active
/// [AppLocalizations]. Never store a label string against this enum —
/// labels move with the user's locale, the identity does not.
enum Department {
  concierge,
  fnb,
  frontDesk,
  housekeeping,
  maintenance,
  roomService;

  String label(AppLocalizations s) {
    switch (this) {
      case Department.concierge:
        return s.deptConcierge;
      case Department.fnb:
        return s.deptFnb;
      case Department.frontDesk:
        return s.deptFrontDesk;
      case Department.housekeeping:
        return s.deptHousekeeping;
      case Department.maintenance:
        return s.deptMaintenance;
      case Department.roomService:
        return s.deptRoomService;
    }
  }
}
