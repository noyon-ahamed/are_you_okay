class AppConstants {
  AppConstants._();

  // API Configuration
  // For Android emulator (localhost): 'http://10.0.2.2:3000/api'
  // For physical device on LAN: 'http://<YOUR_IP>:3000/api'
  // For production (Render): 'https://your-app.onrender.com/api'
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';


  // App Information
  static const String appName = 'Bhalo Achen Ki?';
  static const String appNameBangla = 'ভালো আছেন কি?';
  static const String appTagline = 'Apnar safety, amader dayitto';
  static const String appTaglineBangla = 'আপনার নিরাপত্তা, আমাদের দায়িত্ব';
  static const String appVersion = '1.0.0';

  // Timing Constants (in hours)
  static const int defaultCheckinInterval = 48; // 48 hours
  static const int minimumCheckinInterval = 12; // 12 hours
  static const int maximumCheckinInterval = 168; // 7 days

  // Notification Reminder Times (hours before deadline)
  static const List<int> reminderTimes = [6, 2]; // 6h and 2h before
  static const int criticalReminderMinutes = 30; // 30 min before

  // Emergency Contact Limits
  static const int maxEmergencyContacts = 5;
  static const int minEmergencyContacts = 1;

  // Location
  static const double defaultLatitude = 23.8103; // Dhaka, Bangladesh
  static const double defaultLongitude = 90.4125;

  // Bangladesh Emergency Numbers
  static const Map<String, String> emergencyNumbers = {
    'national_emergency': '999',
    'ambulance': '199',
    'fire_service': '199',
    'police': '100',
    'women_helpline': '109',
    'child_helpline': '1098',
  };

  // Validation
  static const int phoneNumberLength = 11; // 01XXXXXXXXX
  static const String phoneNumberPrefix = '01';
  
  // Storage Keys (Hive box names)
  static const String userBoxName = 'user_box';
  static const String checkinBoxName = 'checkin_box';
  static const String contactsBoxName = 'contacts_box';
  static const String settingsBoxName = 'settings_box';
  
  // SharedPreferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLastCheckin = 'last_checkin';
  static const String keyCheckinInterval = 'checkin_interval';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String checkinsCollection = 'checkins';
  static const String alertsCollection = 'alerts';
  static const String emergencyContactsCollection = 'emergency_contacts';
  
  // Ad Configuration
  static const int bannerAdRefreshInterval = 60; // seconds
  static const int interstitialAdFrequency = 1; // per day
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Offline Sync
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetryAttempts = 3;
  
  // UI Dimensions
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  
  static const double defaultRadius = 12.0;
  static const double largeRadius = 20.0;
  static const double smallRadius = 8.0;
  
  static const double checkinButtonSize = 200.0;
  static const double sosButtonSize = 100.0;
  
  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}