import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should create ThemeProvider with default light mode', () async {
      final provider = ThemeProvider();
      await provider.loadTheme();
      expect(provider.isDarkMode, false);
      expect(provider.currentTheme, AppTheme.lightTheme);
    });

    test('should toggle theme between light and dark', () async {
      final provider = ThemeProvider();
      await provider.loadTheme();
      expect(provider.isDarkMode, false);
      
      await provider.toggleTheme();
      expect(provider.isDarkMode, true);
      expect(provider.currentTheme, AppTheme.darkTheme);
      
      await provider.toggleTheme();
      expect(provider.isDarkMode, false);
      expect(provider.currentTheme, AppTheme.lightTheme);
    });

    test('should persist theme preference to shared_preferences', () async {
      final provider = ThemeProvider();
      await provider.loadTheme();
      
      await provider.setDarkMode(true);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_theme_mode'), true);
    });

    test('should load saved theme preference on init', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_theme_mode', true);
      
      final provider = ThemeProvider();
      await provider.loadTheme();
      expect(provider.isDarkMode, true);
    });
  });
}
