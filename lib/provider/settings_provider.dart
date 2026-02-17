import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/settings_model.dart';
import '../services/hive_service.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final HiveService _hiveService;

  SettingsNotifier(this._hiveService) : super(const SettingsModel()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = _hiveService.getSettings();
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(themeIsDark: !state.themeIsDark);
    await _hiveService.saveSettings(state);
  }

  Future<void> setDarkMode(bool isDark) async {
    state = state.copyWith(themeIsDark: isDark);
    await _hiveService.saveSettings(state);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _hiveService.saveSettings(state);
  }

  Future<void> setCheckinInterval(int hours) async {
    state = state.copyWith(checkinIntervalHours: hours);
    await _hiveService.saveSettings(state);
  }

  Future<void> toggleNotifications() async {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    await _hiveService.saveSettings(state);
  }

  Future<void> toggleLocation() async {
    state = state.copyWith(locationEnabled: !state.locationEnabled);
    await _hiveService.saveSettings(state);
  }

  Future<void> toggleBiometric() async {
    state = state.copyWith(biometricEnabled: !state.biometricEnabled);
    await _hiveService.saveSettings(state);
  }

  Future<void> updateSettings(SettingsModel settings) async {
    state = settings;
    await _hiveService.saveSettings(state);
  }
}

// Global settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  return SettingsNotifier(ref.watch(hiveServiceProvider));
});

// Theme mode provider derived from settings
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeIsDark ? ThemeMode.dark : ThemeMode.light;
});

// Is dark mode provider
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).themeIsDark;
});
