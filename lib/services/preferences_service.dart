import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';

  static Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'vi'; // Default to Vietnamese
    } catch (e) {
      print('Error getting language preference: $e');
      return 'vi'; // Return default value on error
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('Error setting language preference: $e');
    }
  }

  static Future<String> getTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey) ?? 'system'; // Default to system theme
    } catch (e) {
      print('Error getting theme preference: $e');
      return 'system'; // Return default value on error
    }
  }

  static Future<void> setTheme(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme);
    } catch (e) {
      print('Error setting theme preference: $e');
    }
  }
}
