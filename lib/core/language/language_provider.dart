import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _defaultLanguage = 'en';

  late Locale _currentLocale;

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _currentLocale = const Locale('en');
  }

  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    } catch (e) {
      _currentLocale = const Locale('en');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }
}
