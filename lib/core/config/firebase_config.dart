/// Firebase Configuration
/// Contains all Firebase-related configuration and initialization
class FirebaseConfig {
  // Private constructor
  FirebaseConfig._();

  /// Firebase initialization
  static Future<void> initialize() async {
    // Firebase will be initialized in main.dart
    // This class can hold additional Firebase setup logic
  }

  /// Collection names
  static const String usersCollection = 'users';
  static const String emergencyContactsCollection = 'emergency_contacts';
  static const String checkinsCollection = 'checkins';
  static const String alertsCollection = 'alerts';
  static const String appSettingsCollection = 'app_settings';

  /// Storage paths
  static const String profilePicsPath = 'profile_pictures';
  static const String documentsPath = 'documents';

  /// FCM Topics
  static const String allUsersTopic = 'all_users';
  static const String emergencyAlertsTopic = 'emergency_alerts';

  /// Remote Config Keys
  static const String minAppVersionKey = 'min_app_version';
  static const String forceUpdateKey = 'force_update';
  static const String maintenanceModeKey = 'maintenance_mode';
  static const String defaultCheckinIntervalKey = 'default_checkin_interval';
  static const String maxEmergencyContactsKey = 'max_emergency_contacts';
}
