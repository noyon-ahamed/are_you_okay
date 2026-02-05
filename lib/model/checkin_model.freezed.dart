// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkin_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CheckInModel _$CheckInModelFromJson(Map<String, dynamic> json) {
  return _CheckInModel.fromJson(json);
}

/// @nodoc
mixin _$CheckInModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get userId => throw _privateConstructorUsedError;
  @HiveField(2)
  DateTime get timestamp => throw _privateConstructorUsedError;
  @HiveField(3)
  double? get latitude => throw _privateConstructorUsedError;
  @HiveField(4)
  double? get longitude => throw _privateConstructorUsedError;
  @HiveField(5)
  String get method =>
      throw _privateConstructorUsedError; // button, auto, reminder, sos
  @HiveField(6)
  String? get notes => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get isSynced => throw _privateConstructorUsedError;
  @HiveField(8)
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CheckInModelCopyWith<CheckInModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckInModelCopyWith<$Res> {
  factory $CheckInModelCopyWith(
          CheckInModel value, $Res Function(CheckInModel) then) =
      _$CheckInModelCopyWithImpl<$Res, CheckInModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) DateTime timestamp,
      @HiveField(3) double? latitude,
      @HiveField(4) double? longitude,
      @HiveField(5) String method,
      @HiveField(6) String? notes,
      @HiveField(7) bool isSynced,
      @HiveField(8) DateTime? createdAt});
}

/// @nodoc
class _$CheckInModelCopyWithImpl<$Res, $Val extends CheckInModel>
    implements $CheckInModelCopyWith<$Res> {
  _$CheckInModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? timestamp = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? method = null,
    Object? notes = freezed,
    Object? isSynced = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckInModelImplCopyWith<$Res>
    implements $CheckInModelCopyWith<$Res> {
  factory _$$CheckInModelImplCopyWith(
          _$CheckInModelImpl value, $Res Function(_$CheckInModelImpl) then) =
      __$$CheckInModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) DateTime timestamp,
      @HiveField(3) double? latitude,
      @HiveField(4) double? longitude,
      @HiveField(5) String method,
      @HiveField(6) String? notes,
      @HiveField(7) bool isSynced,
      @HiveField(8) DateTime? createdAt});
}

/// @nodoc
class __$$CheckInModelImplCopyWithImpl<$Res>
    extends _$CheckInModelCopyWithImpl<$Res, _$CheckInModelImpl>
    implements _$$CheckInModelImplCopyWith<$Res> {
  __$$CheckInModelImplCopyWithImpl(
      _$CheckInModelImpl _value, $Res Function(_$CheckInModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? timestamp = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? method = null,
    Object? notes = freezed,
    Object? isSynced = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$CheckInModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckInModelImpl implements _CheckInModel {
  const _$CheckInModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.userId,
      @HiveField(2) required this.timestamp,
      @HiveField(3) this.latitude,
      @HiveField(4) this.longitude,
      @HiveField(5) this.method = 'button',
      @HiveField(6) this.notes,
      @HiveField(7) this.isSynced = false,
      @HiveField(8) this.createdAt});

  factory _$CheckInModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckInModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String userId;
  @override
  @HiveField(2)
  final DateTime timestamp;
  @override
  @HiveField(3)
  final double? latitude;
  @override
  @HiveField(4)
  final double? longitude;
  @override
  @JsonKey()
  @HiveField(5)
  final String method;
// button, auto, reminder, sos
  @override
  @HiveField(6)
  final String? notes;
  @override
  @JsonKey()
  @HiveField(7)
  final bool isSynced;
  @override
  @HiveField(8)
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CheckInModel(id: $id, userId: $userId, timestamp: $timestamp, latitude: $latitude, longitude: $longitude, method: $method, notes: $notes, isSynced: $isSynced, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckInModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, timestamp, latitude,
      longitude, method, notes, isSynced, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckInModelImplCopyWith<_$CheckInModelImpl> get copyWith =>
      __$$CheckInModelImplCopyWithImpl<_$CheckInModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckInModelImplToJson(
      this,
    );
  }
}

abstract class _CheckInModel implements CheckInModel {
  const factory _CheckInModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String userId,
      @HiveField(2) required final DateTime timestamp,
      @HiveField(3) final double? latitude,
      @HiveField(4) final double? longitude,
      @HiveField(5) final String method,
      @HiveField(6) final String? notes,
      @HiveField(7) final bool isSynced,
      @HiveField(8) final DateTime? createdAt}) = _$CheckInModelImpl;

  factory _CheckInModel.fromJson(Map<String, dynamic> json) =
      _$CheckInModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get userId;
  @override
  @HiveField(2)
  DateTime get timestamp;
  @override
  @HiveField(3)
  double? get latitude;
  @override
  @HiveField(4)
  double? get longitude;
  @override
  @HiveField(5)
  String get method;
  @override // button, auto, reminder, sos
  @HiveField(6)
  String? get notes;
  @override
  @HiveField(7)
  bool get isSynced;
  @override
  @HiveField(8)
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$CheckInModelImplCopyWith<_$CheckInModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
