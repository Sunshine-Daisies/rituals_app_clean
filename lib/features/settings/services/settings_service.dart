import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyDailyReminders = 'settings_daily_reminders';
  static const String _keySocialNudges = 'settings_social_nudges';
  static const String _keySoundEffects = 'settings_sound_effects';
  static const String _keyThemeMode = 'settings_theme_mode'; // 'system', 'light', 'dark'

  // Singleton instance
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Getters
  bool get dailyReminders => _prefs.getBool(_keyDailyReminders) ?? true;
  bool get socialNudges => _prefs.getBool(_keySocialNudges) ?? true;
  bool get soundEffects => _prefs.getBool(_keySoundEffects) ?? false;
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'dark'; // Default to dark for this app

  // Setters
  Future<void> setDailyReminders(bool value) async {
    await _prefs.setBool(_keyDailyReminders, value);
  }

  Future<void> setSocialNudges(bool value) async {
    await _prefs.setBool(_keySocialNudges, value);
  }

  Future<void> setSoundEffects(bool value) async {
    await _prefs.setBool(_keySoundEffects, value);
  }

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(_keyThemeMode, value);
  }
}
