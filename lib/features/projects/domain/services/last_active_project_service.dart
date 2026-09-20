import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for persisting and restoring the last active project ID
/// across screen navigations and app sessions.
class LastActiveProjectService {
  static const String prefKey = 'last_active_project_id';

  static String? _memoryProjectId;

  /// Returns the current in-memory project ID.
  static String? get currentProjectId => _memoryProjectId;

  /// Sets the in-memory project ID directly (useful for tests or immediate state updates).
  static void setMemoryProjectId(String? id) {
    _memoryProjectId = id;
  }

  /// Resets the in-memory project ID.
  static void resetMemoryProjectId() {
    _memoryProjectId = null;
  }

  final SharedPreferences? _prefs;

  const LastActiveProjectService([this._prefs]);

  /// Singleton instance
  static final LastActiveProjectService instance = LastActiveProjectService();

  /// Loads the persisted last active project ID from SharedPreferences, or in-memory fallback.
  Future<String?> getLastActiveProjectId() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final id = prefs.getString(prefKey);
      _memoryProjectId = id;
      return id;
    } catch (_) {
      return _memoryProjectId;
    }
  }

  /// Saves the last active project ID to SharedPreferences and updates in-memory cache.
  Future<void> setLastActiveProjectId(String id) async {
    _memoryProjectId = id;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(prefKey, id);
    } catch (_) {}
  }

  /// Clears the persisted last active project ID from SharedPreferences and in-memory cache.
  Future<void> clearLastActiveProjectId() async {
    _memoryProjectId = null;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {}
  }

  /// Handles when a project is deleted: clears the ID if it matches the deleted project ID.
  Future<void> onProjectDeleted(String deletedProjectId) async {
    final activeId = await getLastActiveProjectId();
    if (activeId == deletedProjectId) {
      await clearLastActiveProjectId();
    }
  }
}
