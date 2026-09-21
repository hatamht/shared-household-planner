import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing onboarding state.
/// Persists [hasSeenOnboarding] flag to SharedPreferences.
class OnboardingService {
  static const String _prefKey = 'has_seen_onboarding';

  static final OnboardingService instance = OnboardingService._();
  OnboardingService._();

  /// Returns true if the user has already seen the onboarding screen.
  Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Persists that the user has seen the onboarding screen.
  Future<void> markOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  /// Resets the onboarding flag so it will show again on next launch.
  /// Used by the "Replay Onboarding" / "User Guide" option in Settings.
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  /// For use in tests: override SharedPreferences mock value.
  static bool? _memoryOverride;

  /// Set an in-memory override for testing without SharedPreferences.
  static void setTestOverride(bool? value) => _memoryOverride = value;

  /// Clear the test override.
  static void clearTestOverride() => _memoryOverride = null;

  /// Returns status using memory override if set (for testing).
  Future<bool> hasSeenOnboardingForTest() async {
    if (_memoryOverride != null) return _memoryOverride!;
    return hasSeenOnboarding();
  }
}
