import '../../../auth/domain/entities/user_profile.dart' as auth;

/// Represents the complete bootstrap state for dashboard initialization.
/// Contains data from all 3 parallel API calls:
/// 1. me_user → userProfile
/// 2. dashboard/hotel_details → hotelDetails
/// 3. dashboard/numbers → dashboardNumbers
class DashboardBootstrapState {
  final auth.UserProfile? userProfile;
  final HotelDetails? hotelDetails;
  final DashboardNumbers? dashboardNumbers;
  final bool isComplete;

  const DashboardBootstrapState({
    this.userProfile,
    this.hotelDetails,
    this.dashboardNumbers,
    this.isComplete = false,
  });

  /// Empty state before loading
  static const empty = DashboardBootstrapState();

  /// Check if all required data is loaded
  bool get hasAllData =>
      userProfile != null && hotelDetails != null && dashboardNumbers != null;

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    int completed = 0;
    if (userProfile != null) completed++;
    if (hotelDetails != null) completed++;
    if (dashboardNumbers != null) completed++;
    return completed / 3;
  }

  DashboardBootstrapState copyWith({
    auth.UserProfile? userProfile,
    HotelDetails? hotelDetails,
    DashboardNumbers? dashboardNumbers,
    bool? isComplete,
  }) {
    return DashboardBootstrapState(
      userProfile: userProfile ?? this.userProfile,
      hotelDetails: hotelDetails ?? this.hotelDetails,
      dashboardNumbers: dashboardNumbers ?? this.dashboardNumbers,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Hotel details from dashboard/hotel_details API
class HotelDetails {
  final String? name;
  final String? city;
  final int? staff;
  final String? department;
  final int? staffInDepartment;
  final int? totalRooms;
  final int? occupiedRooms;
  final int? checkinsToday;
  final int? checkoutsToday;

  const HotelDetails({
    this.name,
    this.city,
    this.staff,
    this.department,
    this.staffInDepartment,
    this.totalRooms,
    this.occupiedRooms,
    this.checkinsToday,
    this.checkoutsToday,
  });

  factory HotelDetails.fromJson(Map<String, dynamic> json) {
    return HotelDetails(
      name: json['name'] as String?,
      city: json['city'] as String?,
      staff: json['staff'] as int?,
      department: json['department'] as String?,
      staffInDepartment: json['staff_in_department'] as int?,
      totalRooms: json['total_rooms'] as int?,
      occupiedRooms: json['occupied_rooms'] as int?,
      checkinsToday: json['checkins_today'] as int?,
      checkoutsToday: json['checkouts_today'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'staff': staff,
      'department': department,
      'staff_in_department': staffInDepartment,
      'total_rooms': totalRooms,
      'occupied_rooms': occupiedRooms,
      'checkins_today': checkinsToday,
      'checkouts_today': checkoutsToday,
    };
  }
}

/// Dashboard numbers from dashboard/numbers API
class DashboardNumbers {
  final String needsAcknowledgement;
  final String inprogress;
  final String overdue;
  final String notStarted;

  const DashboardNumbers({
    this.needsAcknowledgement = '',
    this.inprogress = '',
    this.overdue = '',
    this.notStarted = '',
  });

  factory DashboardNumbers.fromJson(Map<String, dynamic> json) {
    return DashboardNumbers(
      needsAcknowledgement: json['needs_acknowledgement'],
      inprogress: json['in_progress'],
      overdue: json['overdue'],
      notStarted: json['not_ started'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'needs_acknowledgement': needsAcknowledgement,
      'in_progress': inprogress,
      'overdue': overdue,
      'not_started': notStarted,
    };
  }
}
