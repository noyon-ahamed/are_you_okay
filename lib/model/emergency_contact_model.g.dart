// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmergencyContactModelAdapter extends TypeAdapter<EmergencyContactModel> {
  @override
  final int typeId = 2;

  @override
  EmergencyContactModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmergencyContactModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      phoneNumber: fields[3] as String,
      relationship: fields[4] as String,
      priority: fields[5] as int,
      notifyViaSMS: fields[6] as bool,
      notifyViaCall: fields[7] as bool,
      notifyViaApp: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyContactModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.relationship)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.notifyViaSMS)
      ..writeByte(7)
      ..write(obj.notifyViaCall)
      ..writeByte(8)
      ..write(obj.notifyViaApp)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContactModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EmergencyContactModelImpl _$$EmergencyContactModelImplFromJson(
        Map<String, dynamic> json) =>
    _$EmergencyContactModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      relationship: json['relationship'] as String,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      notifyViaSMS: json['notifyViaSMS'] as bool? ?? true,
      notifyViaCall: json['notifyViaCall'] as bool? ?? false,
      notifyViaApp: json['notifyViaApp'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$EmergencyContactModelImplToJson(
        _$EmergencyContactModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'relationship': instance.relationship,
      'priority': instance.priority,
      'notifyViaSMS': instance.notifyViaSMS,
      'notifyViaCall': instance.notifyViaCall,
      'notifyViaApp': instance.notifyViaApp,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
