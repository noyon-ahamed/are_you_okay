class SettingsModel {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final int checkinIntervalDays;
  final String language;
  final String earthquakeCountry;
  final bool themeIsDark;
  final bool biometricEnabled;
  final DateTime? updatedAt;

  const SettingsModel({
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.checkinIntervalDays = 3, // default: 3 days
    this.language = 'en',
    this.earthquakeCountry = '',
    this.themeIsDark = false,
    this.biometricEnabled = false,
    this.updatedAt,
  });

  SettingsModel copyWith({
    bool? notificationsEnabled,
    bool? locationEnabled,
    int? checkinIntervalDays,
    String? language,
    String? earthquakeCountry,
    bool? themeIsDark,
    bool? biometricEnabled,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      checkinIntervalDays: checkinIntervalDays ?? this.checkinIntervalDays,
      language: language ?? this.language,
      earthquakeCountry: earthquakeCountry ?? this.earthquakeCountry,
      themeIsDark: themeIsDark ?? this.themeIsDark,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
