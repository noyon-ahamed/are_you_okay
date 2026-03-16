import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final sharedPrefsServiceProvider = Provider<SharedPrefsService>((ref) {
  return SharedPrefsService();
});

class SharedPrefsService {
  static final SharedPrefsService _instance = SharedPrefsService._internal();
  factory SharedPrefsService() => _instance;
  SharedPrefsService._internal();

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== First Launch ====================

  bool get isFirstLaunch {
    return _prefs?.getBool(AppConstants.keyIsFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    await _prefs?.setBool(AppConstants.keyIsFirstLaunch, false);
  }

  // ==================== Language ====================

  String get language {
    return _prefs?.getString(AppConstants.keyLanguage) ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    await _prefs?.setString(AppConstants.keyLanguage, lang);
  }

  // ==================== Theme ====================

  String get themeMode {
    return _prefs?.getString(AppConstants.keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(AppConstants.keyThemeMode, mode);
  }

  // ==================== Last Check-in ====================

  DateTime? get lastCheckIn {
    final timestamp = _prefs?.getInt(AppConstants.keyLastCheckin);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setLastCheckIn(DateTime dateTime) async {
    await _prefs?.setInt(
      AppConstants.keyLastCheckin,
      dateTime.millisecondsSinceEpoch,
    );
  }

  // ==================== Check-in Interval ====================

  int get checkinInterval {
    return _prefs?.getInt(AppConstants.keyCheckinInterval) ??
        AppConstants.defaultCheckinIntervalDays;
  }

  Future<void> setCheckinInterval(int days) async {
    await _prefs?.setInt(AppConstants.keyCheckinInterval, days);
  }

  // ==================== Notifications ====================

  bool get notificationsEnabled {
    return _prefs?.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(AppConstants.keyNotificationsEnabled, enabled);
  }

  String? get lastRoute {
    return _prefs?.getString('last_route');
  }

  Future<void> setLastRoute(String route) async {
    await _prefs?.setString('last_route', route);
  }

  // ==================== User Session ====================

  Future<void> setUserId(String uid) async {
    await _prefs?.setString('user_id', uid);
  }

  String? get userId {
    return _prefs?.getString('user_id');
  }

  Future<void> setUserToken(String token) async {
    await _prefs?.setString('user_token', token);
  }

  String? get userToken {
    return _prefs?.getString('user_token');
  }

  bool get isLoggedIn {
    return userId != null && userId!.isNotEmpty;
  }

  // ==================== Clear All ====================

  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  Future<void> logout() async {
    await _prefs?.remove('user_id');
    await _prefs?.remove('user_token');
  }

  Future<void> clearLastCheckIn() async {
    await _prefs?.remove(AppConstants.keyLastCheckin);
  }

  /// Clears ALL user-specific data from SharedPreferences.
  /// This includes history caches, stats, and last activity timestamps.
  Future<void> clearAccountData() async {
    final futures = [
      _prefs?.remove('user_id'),
      _prefs?.remove('user_token'),
      _prefs?.remove(AppConstants.keyLastCheckin),
      _prefs?.remove('checkin_history_cache_v1'),
      _prefs?.remove('checkin_history_cache_meta_v1'),
      _prefs?.remove('mood_history_cache'),
      _prefs?.remove('mood_stats_cache'),
      _prefs?.remove('mood_history_cache_meta'),
      _prefs?.remove('last_route'),
    ];
    await Future.wait(futures.whereType<Future>());
    debugPrint('All account-specific SharedPreferences cleared');
  }

  // ==================== Pending Server Clear ====================
  // Used when user clears data offline — synced to server on next internet

  bool get hasPendingServerClear {
    return _prefs?.getBool('pending_server_clear') ?? false;
  }

  Future<void> setPendingServerClear(bool value) async {
    if (value) {
      await _prefs?.setBool('pending_server_clear', true);
      await _prefs?.setInt(
        'pending_clear_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      await _prefs?.remove('pending_server_clear');
      await _prefs?.remove('pending_clear_timestamp');
    }
  }

  DateTime? get pendingClearTimestamp {
    final ts = _prefs?.getInt('pending_clear_timestamp');
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }
}
