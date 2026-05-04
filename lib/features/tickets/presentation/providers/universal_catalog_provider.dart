import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_locale.dart';
import '../../../../core/i18n/locale_aware_strings.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../auth/presentation/providers/user_profile_controller.dart';
import '../../data/services/universal_catalog_cache.dart';
import '../../data/services/universal_request_service.dart';
import '../../domain/models/universal_catalog.dart';

final universalCatalogCacheProvider = Provider<UniversalCatalogCache>(
  (_) => UniversalCatalogCache(),
);

/// Resolves the language code to use when picking values out of the
/// `name_i18n` / `description_i18n` maps on PRESET requests. Mirrors the
/// existing locale flow used by `LocaleController`.
String _activeLanguageCode(Ref ref) {
  final asyncLocale = ref.watch(localeControllerProvider);
  final locale = asyncLocale.valueOrNull ?? AppLocale.system;
  final concrete =
      locale.toLocale() ?? LocaleAwareStrings.instance.activeLocale;
  return concrete.languageCode;
}

/// Picks the best string out of an i18n map. Falls back to `en`, then to
/// the first available value, then to empty string. Tolerates the API
/// returning either a `Map<String, dynamic>` or null.
String _pickI18n(dynamic raw, String preferred) {
  if (raw is! Map) return '';
  final byPreferred = raw[preferred];
  if (byPreferred is String && byPreferred.isNotEmpty) return byPreferred;
  final byEn = raw['en'];
  if (byEn is String && byEn.isNotEmpty) return byEn;
  for (final v in raw.values) {
    if (v is String && v.isNotEmpty) return v;
  }
  return '';
}

UniversalCatalogSnapshot _parseCatalog(
  List<dynamic> raw,
  String languageCode,
) {
  final departments = <UniversalDepartmentEntry>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final dept = entry['department'];
    if (dept is! Map) continue;
    final deptId = (dept['id'] ?? '').toString();
    final deptCode = (dept['code'] ?? '').toString();
    final deptName = (dept['name'] ?? '').toString();
    final deptEmoji = (dept['mobile_icon'] ?? '').toString();
    final deptIsActive = dept['is_active'];
    if (deptIsActive == false) continue;

    final requests = entry['requests'];
    final items = <UniversalItem>[];
    if (requests is List) {
      for (final r in requests) {
        if (r is! Map) continue;
        if (r['is_enabled'] == false) continue;
        final requestId = (r['id'] ?? '').toString();
        if (requestId.isEmpty) continue;
        final source = (r['source_type'] ?? '').toString().toUpperCase();

        String emoji = '';
        String title = '';
        UniversalSourceType sourceType;

        if (source == 'PRESET') {
          sourceType = UniversalSourceType.preset;
          final preset = r['universal_request_preset'];
          if (preset is! Map) continue;
          if (preset['is_active'] == false) continue;
          emoji = (preset['icon'] ?? '').toString();
          title = _pickI18n(preset['name_i18n'], languageCode);
          if (title.isEmpty) {
            title = (preset['code'] ?? '').toString();
          }
        } else if (source == 'CUSTOM') {
          sourceType = UniversalSourceType.custom;
          final custom = r['universal_request_custom'];
          if (custom is! Map) continue;
          if (custom['is_active'] == false) continue;
          emoji = (custom['icon'] ?? '').toString();
          title = (custom['name'] ?? '').toString();
        } else {
          continue;
        }

        if (emoji.isEmpty) emoji = deptEmoji;
        if (title.isEmpty) continue;

        items.add(
          UniversalItem(
            id: requestId,
            emoji: emoji,
            title: title,
            departmentId: deptId,
            departmentName: deptName,
            departmentCode: deptCode,
            sourceType: sourceType,
          ),
        );
      }
    }

    departments.add(
      UniversalDepartmentEntry(
        id: deptId,
        code: deptCode,
        name: deptName,
        emoji: deptEmoji,
        items: items,
      ),
    );
  }
  return UniversalCatalogSnapshot(departments: departments);
}

/// Hotel-scoped catalog provider. Reads from cache first; only hits the
/// network when the cache is missing or older than [UniversalCatalogCache.defaultTtl].
///
/// Manual refresh is exposed via [refreshUniversalCatalog].
final universalCatalogProvider =
    FutureProvider.autoDispose<UniversalCatalogSnapshot>((ref) async {
  final profile = ref.watch(userProfileProvider);
  if (profile == null) {
    return const UniversalCatalogSnapshot(departments: []);
  }
  final hotelId = profile.userHotelStatus.hotelId;
  if (hotelId.isEmpty) {
    return const UniversalCatalogSnapshot(departments: []);
  }

  final lang = _activeLanguageCode(ref);
  final cache = ref.read(universalCatalogCacheProvider);
  final service = ref.read(universalRequestServiceProvider);

  final cached = await cache.read(hotelId);
  if (cached != null && cached.isFresh(UniversalCatalogCache.defaultTtl)) {
    return _parseCatalog(cached.json, lang);
  }

  try {
    final fresh = await service.fetchCatalogByHotel(hotelId);
    await cache.write(hotelId, fresh);
    return _parseCatalog(fresh, lang);
  } catch (e) {
    // Network failed — serve stale cache rather than blowing up the UI.
    if (cached != null) {
      return _parseCatalog(cached.json, lang);
    }
    rethrow;
  }
});

/// Force-refresh the catalog. Wipes the cache for the active hotel and
/// re-invalidates the provider so listeners refetch.
///
/// Accepts the `WidgetRef` from a `ConsumerWidget` (pull-to-refresh, manual
/// retry buttons). For controller-side use, call [invalidateUniversalCatalog]
/// with a regular `Ref`.
Future<void> refreshUniversalCatalog(WidgetRef ref) async {
  final profile = ref.read(userProfileProvider);
  if (profile == null) return;
  final hotelId = profile.userHotelStatus.hotelId;
  if (hotelId.isEmpty) return;
  await ref.read(universalCatalogCacheProvider).invalidate(hotelId);
  ref.invalidate(universalCatalogProvider);
}

Future<void> invalidateUniversalCatalog(Ref ref) async {
  final profile = ref.read(userProfileProvider);
  if (profile == null) return;
  final hotelId = profile.userHotelStatus.hotelId;
  if (hotelId.isEmpty) return;
  await ref.read(universalCatalogCacheProvider).invalidate(hotelId);
  ref.invalidate(universalCatalogProvider);
}
