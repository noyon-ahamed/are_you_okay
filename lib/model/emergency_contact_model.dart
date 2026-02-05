import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'emergency_contact_model.freezed.dart';
part 'emergency_contact_model.g.dart';

@freezed
@HiveType(typeId: 2)
class EmergencyContactModel with _$EmergencyContactModel {
  const factory EmergencyContactModel({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required String name,
    @HiveField(3) required String phoneNumber,
    @HiveField(4) required String relationship,
    @HiveField(5) @Default(1) int priority, // 1-5
    @HiveField(6) @Default(true) bool notifyViaSMS,
    @HiveField(7) @Default(false) bool notifyViaCall,
    @HiveField(8) @Default(true) bool notifyViaApp,
    @HiveField(9) required DateTime createdAt,
    @HiveField(10) DateTime? updatedAt,
  }) = _EmergencyContactModel;

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactModelFromJson(json);
}