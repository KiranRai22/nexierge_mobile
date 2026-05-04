import 'package:flutter/foundation.dart';

import 'department.dart';

/// Source the universal request originates from on the backend.
enum UniversalSourceType { custom, preset }

/// Maps an API `department.code` to the existing [Department] enum used by
/// the local ticket repository. Unknown codes fall through to housekeeping
/// so a new backend department never crashes the create flow.
Department departmentFromCode(String code) {
  switch (code.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
    case 'fnb':
    case 'foodandbeverage':
      return Department.fnb;
    case 'frontdesk':
      return Department.frontDesk;
    case 'housekeeping':
    case 'housekeepingandlaundry':
      return Department.housekeeping;
    case 'maintenance':
    case 'engineering':
      return Department.maintenance;
    case 'concierge':
      return Department.concierge;
    case 'roomservice':
      return Department.roomService;
    default:
      return Department.housekeeping;
  }
}

/// One selectable service within the universal catalog. Resolved already
/// for the active locale — UI must not do any further i18n lookup on this.
@immutable
class UniversalItem {
  /// `requests[].id` — the active universal request id used when posting
  /// the order to `/universal_requests/order/create`.
  final String id;
  final String emoji;
  final String title;
  final String departmentId;
  final String departmentName;
  final String departmentCode;
  final UniversalSourceType sourceType;

  const UniversalItem({
    required this.id,
    required this.emoji,
    required this.title,
    required this.departmentId,
    required this.departmentName,
    required this.departmentCode,
    required this.sourceType,
  });

  Department get department => departmentFromCode(departmentCode);
}

/// One department bucket inside the catalog (used to render the section
/// headers + grid in the create screen).
@immutable
class UniversalDepartmentEntry {
  final String id;
  final String code;
  final String name;
  final String emoji;
  final List<UniversalItem> items;

  const UniversalDepartmentEntry({
    required this.id,
    required this.code,
    required this.name,
    required this.emoji,
    required this.items,
  });
}

/// Whole catalog snapshot — used by both the cache layer and the provider.
@immutable
class UniversalCatalogSnapshot {
  final List<UniversalDepartmentEntry> departments;

  const UniversalCatalogSnapshot({required this.departments});

  bool get isEmpty => departments.every((d) => d.items.isEmpty);

  List<UniversalItem> search(String query) {
    if (query.isEmpty) {
      return [for (final d in departments) ...d.items];
    }
    final q = query.toLowerCase();
    return [
      for (final d in departments)
        for (final i in d.items)
          if (i.title.toLowerCase().contains(q) ||
              d.name.toLowerCase().contains(q))
            i,
    ];
  }
}
