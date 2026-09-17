import 'package:shared_preferences/shared_preferences.dart';

class DefaultSplitModeService {
  final SharedPreferences? _prefs;
  final bool isInMemoryOnly;
  final Map<String, String> _inMemoryCategoryDefaults = {};
  final Map<String, String> _inMemoryPersonDefaults = {};

  static const String categoryPrefix = 'default_split_mode_cat_';
  static const String personPrefix = 'default_split_mode_person_';

  DefaultSplitModeService([this._prefs, this.isInMemoryOnly = false]);

  static DefaultSplitModeService? _instance;
  static DefaultSplitModeService get instance => _instance ??= DefaultSplitModeService();

  static void setMockInstance(DefaultSplitModeService service) {
    _instance = service;
  }

  Future<void> setDefaultSplitModeForCategory(String categoryId, String splitMode) async {
    final key = '$categoryPrefix$categoryId';
    _inMemoryCategoryDefaults[categoryId] = splitMode;
    if (isInMemoryOnly) return;
    if (_prefs != null) {
      await _prefs!.setString(key, splitMode);
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, splitMode);
      } catch (_) {}
    }
  }

  Future<String?> getDefaultSplitModeForCategory(String categoryId) async {
    if (_inMemoryCategoryDefaults.containsKey(categoryId)) {
      return _inMemoryCategoryDefaults[categoryId];
    }
    if (isInMemoryOnly) return null;
    final key = '$categoryPrefix$categoryId';
    if (_prefs != null) {
      final val = _prefs!.getString(key);
      if (val != null) _inMemoryCategoryDefaults[categoryId] = val;
      return val;
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final val = prefs.getString(key);
        if (val != null) _inMemoryCategoryDefaults[categoryId] = val;
        return val;
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> setDefaultSplitModeForPerson(String personName, String splitMode) async {
    final key = '$personPrefix$personName';
    _inMemoryPersonDefaults[personName] = splitMode;
    if (isInMemoryOnly) return;
    if (_prefs != null) {
      await _prefs!.setString(key, splitMode);
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, splitMode);
      } catch (_) {}
    }
  }

  Future<String?> getDefaultSplitModeForPerson(String personName) async {
    if (_inMemoryPersonDefaults.containsKey(personName)) {
      return _inMemoryPersonDefaults[personName];
    }
    if (isInMemoryOnly) return null;
    final key = '$personPrefix$personName';
    if (_prefs != null) {
      final val = _prefs!.getString(key);
      if (val != null) _inMemoryPersonDefaults[personName] = val;
      return val;
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final val = prefs.getString(key);
        if (val != null) _inMemoryPersonDefaults[personName] = val;
        return val;
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> clearDefaults() async {
    _inMemoryCategoryDefaults.clear();
    _inMemoryPersonDefaults.clear();
    if (isInMemoryOnly) return;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
            (k) => k.startsWith(categoryPrefix) || k.startsWith(personPrefix),
          );
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
