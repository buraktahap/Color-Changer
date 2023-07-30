import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _baseUrlKey = 'baseUrl';

  static Future<void> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
  }

  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey);
  }
}
