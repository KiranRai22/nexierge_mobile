import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/entities/user_profile.dart';

class UserProfileService {
  static UserProfileService instance = UserProfileService._();

  static const String _profileKey = 'user_profile';
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';

  // Cache token for synchronous access
  String? _cachedToken;

  UserProfileService._();

  /// Save user profile to shared preferences
  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString(_profileKey, profileJson);
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Get saved user profile from shared preferences
  Future<UserProfile?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      if (profileJson == null) return null;

      final decoded = jsonDecode(profileJson);

      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      } else {
        // Clear invalid data
        await clearProfile();
        return null;
      }
    } catch (e) {
      debugPrint('[UserProfileService] Error loading profile: $e');
      // Clear corrupted data
      await clearProfile();
      return null;
    }
  }

  /// Clear saved user profile
  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  /// Save auth token and expiry time
  Future<void> saveAuthToken(String token, {DateTime? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (expiry != null) {
        await prefs.setInt(_tokenExpiryKey, expiry.millisecondsSinceEpoch);
      }
      // Cache token for synchronous access
      _cachedToken = token;
    } catch (e) {
      throw Exception('Failed to save auth token: $e');
    }
  }

  /// Get saved auth token (async version)
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      _cachedToken = token; // Update cache
      return token;
    } catch (e) {
      _cachedToken = null;
      return null;
    }
  }

  /// Get cached auth token synchronously
  String? getCachedAuthToken() {
    return _cachedToken;
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryMs = prefs.getInt(_tokenExpiryKey);
      if (expiryMs == null) return false; // No expiry set

      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true; // Assume expired on error
    }
  }

  /// Clear auth token and expiry
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([prefs.remove(_tokenKey), prefs.remove(_tokenExpiryKey)]);
    _cachedToken = null; // Clear cache
  }

  /// Clear all user data (profile + token)
  Future<void> clearAllUserData() async {
    await Future.wait([clearProfile(), clearAuthToken()]);
  }
}
