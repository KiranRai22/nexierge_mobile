import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable section identifiers used by the Profile screen. Keep in sync
/// with the section ids passed to [ProfileInfoSection]/[ProfilePreferencesSection].
class ProfileSectionId {
  static const account = 'account';
  static const work = 'work';
  static const hotel = 'hotel';
  static const subscription = 'subscription';
  static const systemAccess = 'system_access';
  static const preferences = 'preferences';

  const ProfileSectionId._();
}

/// Per-section expand/collapse state for the Profile screen, keyed by a
/// stable section id (see [ProfileSectionId]).
///
/// Lifted out of widget state so:
///   1. Section toggles can't be mis-attributed to other sections when
///      the parent rebuilds (e.g. on scroll).
///   2. The state survives navigating away from and back to the Profile
///      tab — no widget lifecycle erases it.
class ProfileSectionExpansionNotifier extends StateNotifier<Map<String, bool>> {
  ProfileSectionExpansionNotifier() : super(_defaults);

  /// Default expanded state per section. Info sections default to
  /// expanded; the preferences section defaults to collapsed (matches the
  /// existing UX from before the refactor).
  static const Map<String, bool> _defaults = {
    ProfileSectionId.account: true,
    ProfileSectionId.work: true,
    ProfileSectionId.hotel: true,
    ProfileSectionId.subscription: true,
    ProfileSectionId.systemAccess: true,
    ProfileSectionId.preferences: false,
  };

  bool isExpanded(String sectionId) =>
      state[sectionId] ?? _defaults[sectionId] ?? true;

  void toggle(String sectionId) {
    state = {...state, sectionId: !isExpanded(sectionId)};
  }
}

final profileSectionExpansionProvider = StateNotifierProvider<
    ProfileSectionExpansionNotifier, Map<String, bool>>((ref) {
  return ProfileSectionExpansionNotifier();
});

/// Convenience selector: read just the expanded boolean for one section.
final profileSectionExpandedProvider = Provider.family<bool, String>((
  ref,
  sectionId,
) {
  final map = ref.watch(profileSectionExpansionProvider);
  return map[sectionId] ??
      ProfileSectionExpansionNotifier._defaults[sectionId] ??
      true;
});
