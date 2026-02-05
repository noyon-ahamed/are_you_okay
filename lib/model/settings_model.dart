import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'settings_model.freezed.dart';
part 'settings_model.g.dart';

@freezed
@HiveType(typeId: 3)
class SettingsModel with _$SettingsModel {
  const factory SettingsModel({
    @HiveField(0) @Default('bn') String language,
    @HiveField(1) @Default('system') String themeMode, // light, dark, system
    @HiveField(2) @Default(true) bool notificationsEnabled,
    @HiveField(3) @Default(true) bool reminderNotifications,
    @HiveField(4) @Default(true) bool alertNotifications,
    @HiveField(5) @Default(48) int checkinIntervalHours,
    @HiveField(6) @Default(true) bool locationEnabled,
    @HiveField(7) @Default(false) bool soundEnabled,
    @HiveField(8) @Default(true) bool vibrationEnabled,
    @HiveField(9) DateTime? updatedAt,
  }) = _SettingsModel;

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);
}