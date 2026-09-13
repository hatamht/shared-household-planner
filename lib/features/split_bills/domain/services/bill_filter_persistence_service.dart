import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/bill_filter.dart';

/// Service responsible for persisting and restoring [BillFilter] state
/// across screen navigations and app sessions.
class BillFilterPersistenceService {
  static const String prefKey = 'bill_filter_state';

  static BillFilter _memoryFilter = const BillFilter.initial();

  /// Returns the current in-memory filter.
  static BillFilter get currentFilter => _memoryFilter;

  /// Sets the in-memory filter directly (useful for tests or immediate state updates).
  static void setMemoryFilter(BillFilter filter) {
    _memoryFilter = filter;
  }

  /// Resets the in-memory filter.
  static void resetMemoryFilter() {
    _memoryFilter = const BillFilter.initial();
  }

  final SharedPreferences? _prefs;

  const BillFilterPersistenceService([this._prefs]);

  /// Loads the persisted [BillFilter] from SharedPreferences, or in-memory fallback.
  Future<BillFilter> loadFilter() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final filter = BillFilter.fromJson(map);
        _memoryFilter = filter;
        return filter;
      }
    } catch (_) {
      // Fallback to memory filter if prefs error
    }
    return _memoryFilter;
  }

  /// Saves the [BillFilter] to SharedPreferences and updates in-memory cache.
  Future<void> saveFilter(BillFilter filter) async {
    _memoryFilter = filter;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(filter.toJson());
      await prefs.setString(prefKey, jsonStr);
    } catch (_) {}
  }

  /// Clears the persisted [BillFilter] from SharedPreferences and resets memory cache.
  Future<void> clearFilter() async {
    _memoryFilter = const BillFilter.initial();
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {}
  }
}
