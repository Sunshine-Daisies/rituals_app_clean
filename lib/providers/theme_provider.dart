import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/services/settings_service.dart';

// Theme Mode State Notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeModeNotifier(this._settingsService) : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final themeMode = _settingsService.themeMode;
    state = _themeModeFromString(themeMode);
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _settingsService.setThemeMode(_themeModeToString(mode));
  }
}

// Theme Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final settingsService = SettingsService();
  return ThemeModeNotifier(settingsService);
});
