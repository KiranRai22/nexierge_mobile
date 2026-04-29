import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/dashboard_bootstrap_state.dart';

/// Local storage service for dashboard bootstrap data.
/// Persists hotel details and dashboard numbers across app restarts.
class DashboardDataService {
  static const String _hotelDetailsKey = 'dashboard_hotel_details';
  static const String _dashboardNumbersKey = 'dashboard_numbers';
  static const String _bootstrapCompleteKey = 'dashboard_bootstrap_complete';
  static const String _bootstrapTimestampKey = 'dashboard_bootstrap_timestamp';

  /// Save hotel details to local storage
  Future<void> saveHotelDetails(HotelDetails details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(details.toJson());
      await prefs.setString(_hotelDetailsKey, json);
      debugPrint('[DashboardDataService] Hotel details saved');
    } catch (e) {
      debugPrint('[DashboardDataService] Failed to save hotel details: $e');
      throw Exception('Failed to save hotel details: $e');
    }
  }

  /// Get hotel details from local storage
  Future<HotelDetails?> getHotelDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_hotelDetailsKey);
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      return HotelDetails.fromJson(map);
    } catch (e) {
      debugPrint('[DashboardDataService] Failed to load hotel details: $e');
      await _clearHotelDetails();
      return null;
    }
  }

  /// Save dashboard numbers to local storage
  Future<void> saveDashboardNumbers(DashboardNumbers numbers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(numbers.toJson());
      await prefs.setString(_dashboardNumbersKey, json);
      debugPrint('[DashboardDataService] Dashboard numbers saved');
    } catch (e) {
      debugPrint('[DashboardDataService] Failed to save dashboard numbers: $e');
      throw Exception('Failed to save dashboard numbers: $e');
    }
  }

  /// Get dashboard numbers from local storage
  Future<DashboardNumbers?> getDashboardNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_dashboardNumbersKey);
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      return DashboardNumbers.fromJson(map);
    } catch (e) {
      debugPrint('[DashboardDataService] Failed to load dashboard numbers: $e');
      await _clearDashboardNumbers();
      return null;
    }
  }

  /// Mark bootstrap as complete with timestamp
  Future<void> markBootstrapComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_bootstrapCompleteKey, true);
      await prefs.setInt(
        _bootstrapTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('[DashboardDataService] Bootstrap marked complete');
    } catch (e) {
      debugPrint('[DashboardDataService] Failed to mark bootstrap complete: $e');
    }
  }

  /// Check if bootstrap is complete and data is fresh (within 24 hours)
  Future<bool> isBootstrapComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(_bootstrapCompleteKey) ?? false;
      if (!isComplete) return false;

      final timestamp = prefs.getInt(_bootstrapTimestampKey);
      if (timestamp == null) return false;

      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final diff = now.difference(lastUpdate);

      // Data is considered fresh if less than 24 hours old
      return diff.inHours < 24;
    } catch (e) {
      debugPrint('[DashboardDataService] Failed to check bootstrap status: $e');
      return false;
    }
  }

  /// Get last bootstrap timestamp
  Future<DateTime?> getLastBootstrapTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_bootstrapTimestampKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Clear all dashboard data (used on logout)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_hotelDetailsKey),
        prefs.remove(_dashboardNumbersKey),
        prefs.remove(_bootstrapCompleteKey),
        prefs.remove(_bootstrapTimestampKey),
      ]);
      debugPrint('[DashboardDataService] All dashboard data cleared');
    } catch (e) {
      debugPrint('[DashboardDataService] Failed to clear data: $e');
    }
  }

  Future<void> _clearHotelDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hotelDetailsKey);
  }

  Future<void> _clearDashboardNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dashboardNumbersKey);
  }
}
