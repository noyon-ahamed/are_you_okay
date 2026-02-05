// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 3;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      language: fields[0] as String,
      themeMode: fields[1] as String,
      notificationsEnabled: fields[2] as bool,
      reminderNotifications: fields[3] as bool,
      alertNotifications: fields[4] as bool,
      checkinIntervalHours: fields[5] as int,
      locationEnabled: fields[6] as bool,
      soundEnabled: fields[7] as bool,
      vibrationEnabled: fields[8] as bool,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.language)
      ..writeByte(1)
      ..write(obj.themeMode)
      ..writeByte(2)
      ..write(obj.notificationsEnabled)
      ..writeByte(3)
      ..write(obj.reminderNotifications)
      ..writeByte(4)
      ..write(obj.alertNotifications)
      ..writeByte(5)
      ..write(obj.checkinIntervalHours)
      ..writeByte(6)
      ..write(obj.locationEnabled)
      ..writeByte(7)
      ..write(obj.soundEnabled)
      ..writeByte(8)
      ..write(obj.vibrationEnabled)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsModelImpl _$$SettingsModelImplFromJson(Map<String, dynamic> json) =>
    _$SettingsModelImpl(
      language: json['language'] as String? ?? 'bn',
      themeMode: json['themeMode'] as String? ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      reminderNotifications: json['reminderNotifications'] as bool? ?? true,
      alertNotifications: json['alertNotifications'] as bool? ?? true,
      checkinIntervalHours:
          (json['checkinIntervalHours'] as num?)?.toInt() ?? 48,
      locationEnabled: json['locationEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SettingsModelImplToJson(_$SettingsModelImpl instance) =>
    <String, dynamic>{
      'language': instance.language,
      'themeMode': instance.themeMode,
      'notificationsEnabled': instance.notificationsEnabled,
      'reminderNotifications': instance.reminderNotifications,
      'alertNotifications': instance.alertNotifications,
      'checkinIntervalHours': instance.checkinIntervalHours,
      'locationEnabled': instance.locationEnabled,
      'soundEnabled': instance.soundEnabled,
      'vibrationEnabled': instance.vibrationEnabled,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
