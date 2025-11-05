import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appName = 'SANA Wellness';
  static const String appVersion = '0.1.0';

  // API Configuration
  static const String apiBaseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api');

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';

  // Instances
  static late final FlutterSecureStorage secureStorage;
  static late final SharedPreferences prefs;

  static Future<void> initialize() async {
    secureStorage = const FlutterSecureStorage();
    prefs = await SharedPreferences.getInstance();
  }

  // Token management
  static Future<String?> getAccessToken() async {
    return await secureStorage.read(key: accessTokenKey);
  }

  static Future<void> setAccessToken(String token) async {
    await secureStorage.write(key: accessTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: refreshTokenKey);
  }

  static Future<void> setRefreshToken(String token) async {
    await secureStorage.write(key: refreshTokenKey, value: token);
  }

  static Future<void> clearTokens() async {
    await secureStorage.delete(key: accessTokenKey);
    await secureStorage.delete(key: refreshTokenKey);
  }

  // User data
  static Future<void> setUserId(String userId) async {
    await prefs.setString(userIdKey, userId);
  }

  static String? getUserId() {
    return prefs.getString(userIdKey);
  }

  static Future<void> setUserRole(String role) async {
    await prefs.setString(userRoleKey, role);
  }

  static String? getUserRole() {
    return prefs.getString(userRoleKey);
  }

  static Future<void> clearUserData() async {
    await clearTokens();
    await prefs.remove(userIdKey);
    await prefs.remove(userRoleKey);
  }
}
