class SettingsModel {
  final bool notificationsEnabled;
  final bool smsAlerts;
  final bool wellnessReminders;
  final bool emergencyAlerts;
  final bool locationEnabled;
  final int checkinIntervalDays;
  final String language;
  final String earthquakeCountry;
  final bool themeIsDark;
  final bool biometricEnabled;
  final bool voiceSOSEnabled;
  final DateTime? updatedAt;

  const SettingsModel({
    this.notificationsEnabled = true,
    this.smsAlerts = true,
    this.wellnessReminders = true,
    this.emergencyAlerts = true,
    this.locationEnabled = true,
    this.checkinIntervalDays = 3, // default: 3 days
    this.language = 'en',
    this.earthquakeCountry = '',
    this.themeIsDark = false,
    this.biometricEnabled = false,
    this.voiceSOSEnabled = false,
    this.updatedAt,
  });

  SettingsModel copyWith({
    bool? notificationsEnabled,
    bool? smsAlerts,
    bool? wellnessReminders,
    bool? emergencyAlerts,
    bool? locationEnabled,
    int? checkinIntervalDays,
    String? language,
    String? earthquakeCountry,
    bool? themeIsDark,
    bool? biometricEnabled,
    bool? voiceSOSEnabled,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      wellnessReminders: wellnessReminders ?? this.wellnessReminders,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      checkinIntervalDays: checkinIntervalDays ?? this.checkinIntervalDays,
      language: language ?? this.language,
      earthquakeCountry: earthquakeCountry ?? this.earthquakeCountry,
      themeIsDark: themeIsDark ?? this.themeIsDark,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      voiceSOSEnabled: voiceSOSEnabled ?? this.voiceSOSEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
