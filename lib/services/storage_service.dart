import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> setToken(String token) async {
    return await _prefs?.setString(AppConstants.tokenKey, token) ?? false;
  }

  static String? getToken() {
    return _prefs?.getString(AppConstants.tokenKey);
  }

  static Future<bool> setUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    return await _prefs?.setString(AppConstants.userKey, userJson) ?? false;
  }

  static User? getUser() {
    final userJson = _prefs?.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  static Future<bool> setThemeMode(String mode) async {
    return await _prefs?.setString(AppConstants.themeModeKey, mode) ?? false;
  }

  static String getThemeMode() {
    return _prefs?.getString(AppConstants.themeModeKey) ?? 'light';
  }

  static Future<void> clearSession() async {
    await _prefs?.remove(AppConstants.tokenKey);
    await _prefs?.remove(AppConstants.userKey);
  }
}
