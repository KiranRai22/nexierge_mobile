import 'package:shared_preferences/shared_preferences.dart';

/// Manages device FCM token persistence in shared_preferences.
/// Token is saved after Firebase initialization and retrieved during login.
class DeviceTokenService {
  static const String _tokenKey = 'device.fcm_token';

  /// Save the device token to shared preferences.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieve the saved device token. Returns null if not available.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Clear the device token (e.g., on logout).
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
