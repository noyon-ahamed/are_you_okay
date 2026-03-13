import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/settings_model.dart';
import '../services/hive_service.dart';
import '../services/api/auth_api_service.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';

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

  Future<void> setEarthquakeCountry(String country) async {
    state = state.copyWith(earthquakeCountry: country);
    await _hiveService.saveSettings(state);
    try {
      await AuthApiService().updateNotificationPreferences(
        earthquakeCountry: country,
      );
    } catch (_) {}
  }

  Future<void> setCheckinInterval(int days) async {
    state = state.copyWith(checkinIntervalDays: days);
    await _hiveService.saveSettings(state);
    try {
      await AuthApiService().updateNotificationPreferences(
        notificationEnabled: state.notificationsEnabled,
        smsAlerts: state.smsAlerts,
        wellnessReminders: state.wellnessReminders,
        emergencyAlerts: state.emergencyAlerts,
      );
    } catch (_) {}
  }

  Future<void> toggleNotifications() async {
    final newValue = !state.notificationsEnabled;
    state = state.copyWith(notificationsEnabled: newValue);
    await _hiveService.saveSettings(state);

    // Persist the flag so the background isolate can also read it
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', newValue);

    try {
      await AuthApiService().updateNotificationPreferences(
        notificationEnabled: newValue,
        smsAlerts: state.smsAlerts,
        wellnessReminders: state.wellnessReminders,
        emergencyAlerts: state.emergencyAlerts,
        earthquakeCountry: state.earthquakeCountry,
      );
    } catch (_) {}

    final notifService = LocalNotificationService();
    await notifService.initialize(onNotificationTap: (_) {});

    if (newValue) {
      // Notifications turned ON → re-register background task and run an immediate check
      await BackgroundService.registerPeriodicTask();
      await BackgroundService.runImmediateReminderCheck();
    } else {
      // Notifications turned OFF → cancel all notifications and background task
      await notifService.cancelAllNotifications();
      await BackgroundService.cancelAllTasks();
    }
  }

  Future<void> setNotificationPreferences({
    bool? pushNotifications,
    bool? smsAlerts,
    bool? wellnessReminders,
    bool? emergencyAlerts,
  }) async {
    final nextState = state.copyWith(
      notificationsEnabled: pushNotifications ?? state.notificationsEnabled,
      smsAlerts: smsAlerts ?? state.smsAlerts,
      wellnessReminders: wellnessReminders ?? state.wellnessReminders,
      emergencyAlerts: emergencyAlerts ?? state.emergencyAlerts,
      updatedAt: DateTime.now(),
    );

    final previousPush = state.notificationsEnabled;
    final previousWellness = state.wellnessReminders;
    state = nextState;
    await _hiveService.saveSettings(state);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', state.notificationsEnabled);

    try {
      await AuthApiService().updateNotificationPreferences(
        notificationEnabled: state.notificationsEnabled,
        smsAlerts: state.smsAlerts,
        wellnessReminders: state.wellnessReminders,
        emergencyAlerts: state.emergencyAlerts,
        earthquakeCountry: state.earthquakeCountry,
      );
    } catch (_) {}

    final notifService = LocalNotificationService();
    await notifService.initialize(onNotificationTap: (_) {});

    if (previousPush != state.notificationsEnabled ||
        previousWellness != state.wellnessReminders) {
      if (state.notificationsEnabled && state.wellnessReminders) {
        await BackgroundService.registerPeriodicTask();
        await BackgroundService.runImmediateReminderCheck();
      } else {
        await notifService.cancelCheckinReminders();
      }

      if (!state.notificationsEnabled) {
        await notifService.cancelAllNotifications();
        await BackgroundService.cancelAllTasks();
      }
    }
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

/// Session-only override for earthquake country browsing.
/// This lets the user preview another country without replacing
/// the auto-detected/persisted home country permanently.
final earthquakeCountryOverrideProvider = StateProvider<String?>((ref) => null);
