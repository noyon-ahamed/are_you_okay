// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      uid: fields[0] as String,
      phoneNumber: fields[1] as String,
      email: fields[2] as String?,
      name: fields[3] as String,
      profilePicture: fields[4] as String?,
      dateOfBirth: fields[5] as DateTime?,
      gender: fields[6] as String?,
      language: fields[7] as String,
      checkinInterval: fields[8] as int,
      isActive: fields[9] as bool,
      isPremium: fields[10] as bool,
      address: fields[11] as String?,
      bloodGroup: fields[12] as String?,
      medicalInfo: fields[13] as String?,
      lastCheckIn: fields[14] as DateTime?,
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.profilePicture)
      ..writeByte(5)
      ..write(obj.dateOfBirth)
      ..writeByte(6)
      ..write(obj.gender)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.checkinInterval)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.isPremium)
      ..writeByte(11)
      ..write(obj.address)
      ..writeByte(12)
      ..write(obj.bloodGroup)
      ..writeByte(13)
      ..write(obj.medicalInfo)
      ..writeByte(14)
      ..write(obj.lastCheckIn)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      uid: json['uid'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      profilePicture: json['profilePicture'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String?,
      language: json['language'] as String? ?? 'bn',
      checkinInterval: (json['checkinInterval'] as num?)?.toInt() ?? 48,
      isActive: json['isActive'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
      address: json['address'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      medicalInfo: json['medicalInfo'] as String?,
      lastCheckIn: json['lastCheckIn'] == null
          ? null
          : DateTime.parse(json['lastCheckIn'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'name': instance.name,
      'profilePicture': instance.profilePicture,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'language': instance.language,
      'checkinInterval': instance.checkinInterval,
      'isActive': instance.isActive,
      'isPremium': instance.isPremium,
      'address': instance.address,
      'bloodGroup': instance.bloodGroup,
      'medicalInfo': instance.medicalInfo,
      'lastCheckIn': instance.lastCheckIn?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
