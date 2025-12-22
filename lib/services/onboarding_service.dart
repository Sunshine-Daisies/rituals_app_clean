import 'package:shared_preferences/shared_preferences.dart';

/// Manages onboarding state for new users
class OnboardingService {
  static const String _hasSeenWelcomeKey = 'has_seen_welcome';
  static const String _hasCompletedFirstRitualKey = 'has_completed_first_ritual';
  static const String _isFirstLaunchKey = 'is_first_launch';

  /// Check if user has seen welcome screens
  static Future<bool> hasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenWelcomeKey) ?? false;
  }

  /// Mark welcome screens as seen
  static Future<void> markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomeKey, true);
  }

  /// Check if user has completed their first ritual
  static Future<bool> hasCompletedFirstRitual() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedFirstRitualKey) ?? false;
  }

  /// Mark first ritual as completed (triggers celebration)
  static Future<void> markFirstRitualCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedFirstRitualKey, true);
  }

  /// Check if this is the user's first launch after signup
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  /// Mark first launch as complete
  static Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  /// Check if user needs onboarding
  static Future<bool> needsOnboarding() async {
    final seenWelcome = await hasSeenWelcome();
    return !seenWelcome;
  }

  /// Reset onboarding state (for testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenWelcomeKey);
    await prefs.remove(_hasCompletedFirstRitualKey);
    await prefs.setBool(_isFirstLaunchKey, true);
  }
}
