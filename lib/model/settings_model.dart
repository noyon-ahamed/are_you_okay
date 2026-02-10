class SettingsModel {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final int checkinIntervalHours;
  final String language;
  final bool themeIsDark;
  final DateTime? updatedAt;

  const SettingsModel({
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.checkinIntervalHours = 24,
    this.language = 'en',
    this.themeIsDark = false,
    this.updatedAt,
  });

  SettingsModel copyWith({
    bool? notificationsEnabled,
    bool? locationEnabled,
    int? checkinIntervalHours,
    String? language,
    bool? themeIsDark,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      checkinIntervalHours: checkinIntervalHours ?? this.checkinIntervalHours,
      language: language ?? this.language,
      themeIsDark: themeIsDark ?? this.themeIsDark,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
