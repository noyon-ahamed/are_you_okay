import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'checkin_model.freezed.dart';
part 'checkin_model.g.dart';

@freezed
@HiveType(typeId: 1)
class CheckInModel with _$CheckInModel {
  const factory CheckInModel({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required DateTime timestamp,
    @HiveField(3) double? latitude,
    @HiveField(4) double? longitude,
    @HiveField(5) @Default('button') String method, // button, auto, reminder, sos
    @HiveField(6) String? notes,
    @HiveField(7) @Default(false) bool isSynced,
    @HiveField(8) DateTime? createdAt,
  }) = _CheckInModel;

  factory CheckInModel.fromJson(Map<String, dynamic> json) =>
      _$CheckInModelFromJson(json);
}