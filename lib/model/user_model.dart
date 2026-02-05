import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
@HiveType(typeId: 0)
class UserModel with _$UserModel {
  const factory UserModel({
    @HiveField(0) required String uid,
    @HiveField(1) required String phoneNumber,
    @HiveField(2) String? email,
    @HiveField(3) required String name,
    @HiveField(4) String? profilePicture,
    @HiveField(5) DateTime? dateOfBirth,
    @HiveField(6) String? gender,
    @HiveField(7) @Default('bn') String language,
    @HiveField(8) @Default(48) int checkinInterval, // hours
    @HiveField(9) @Default(true) bool isActive,
    @HiveField(10) @Default(false) bool isPremium,
    @HiveField(11) String? address,
    @HiveField(12) String? bloodGroup,
    @HiveField(13) String? medicalInfo,
    @HiveField(14) DateTime? lastCheckIn,
    @HiveField(15) required DateTime createdAt,
    @HiveField(16) required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}