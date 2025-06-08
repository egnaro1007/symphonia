class SimplePreferencesService {
  static String _currentLanguage = 'vi';
  static String _currentTheme = 'system';

  static Future<String> getLanguage() async {
    return _currentLanguage;
  }

  static Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
  }

  static Future<String> getTheme() async {
    return _currentTheme;
  }

  static Future<void> setTheme(String theme) async {
    _currentTheme = theme;
  }
}
