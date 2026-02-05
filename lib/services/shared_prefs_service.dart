import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class SharedPrefsService {
  static final SharedPrefsService _instance = SharedPrefsService._internal();
  factory SharedPrefsService() => _instance;
  SharedPrefsService._internal();

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
    return _prefs?.getString(AppConstants.keyLanguage) ?? 'bn';
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
        AppConstants.defaultCheckinInterval;
  }

  Future<void> setCheckinInterval(int hours) async {
    await _prefs?.setInt(AppConstants.keyCheckinInterval, hours);
  }

  // ==================== Notifications ====================
  
  bool get notificationsEnabled {
    return _prefs?.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(AppConstants.keyNotificationsEnabled, enabled);
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
}