// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emergency_contact_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EmergencyContactModel _$EmergencyContactModelFromJson(
    Map<String, dynamic> json) {
  return _EmergencyContactModel.fromJson(json);
}

/// @nodoc
mixin _$EmergencyContactModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get userId => throw _privateConstructorUsedError;
  @HiveField(2)
  String get name => throw _privateConstructorUsedError;
  @HiveField(3)
  String get phoneNumber => throw _privateConstructorUsedError;
  @HiveField(4)
  String get relationship => throw _privateConstructorUsedError;
  @HiveField(5)
  int get priority => throw _privateConstructorUsedError; // 1-5
  @HiveField(6)
  bool get notifyViaSMS => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get notifyViaCall => throw _privateConstructorUsedError;
  @HiveField(8)
  bool get notifyViaApp => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(10)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EmergencyContactModelCopyWith<EmergencyContactModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmergencyContactModelCopyWith<$Res> {
  factory $EmergencyContactModelCopyWith(EmergencyContactModel value,
          $Res Function(EmergencyContactModel) then) =
      _$EmergencyContactModelCopyWithImpl<$Res, EmergencyContactModel>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) String name,
      @HiveField(3) String phoneNumber,
      @HiveField(4) String relationship,
      @HiveField(5) int priority,
      @HiveField(6) bool notifyViaSMS,
      @HiveField(7) bool notifyViaCall,
      @HiveField(8) bool notifyViaApp,
      @HiveField(9) DateTime createdAt,
      @HiveField(10) DateTime? updatedAt});
}

/// @nodoc
class _$EmergencyContactModelCopyWithImpl<$Res,
        $Val extends EmergencyContactModel>
    implements $EmergencyContactModelCopyWith<$Res> {
  _$EmergencyContactModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? phoneNumber = null,
    Object? relationship = null,
    Object? priority = null,
    Object? notifyViaSMS = null,
    Object? notifyViaCall = null,
    Object? notifyViaApp = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      relationship: null == relationship
          ? _value.relationship
          : relationship // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      notifyViaSMS: null == notifyViaSMS
          ? _value.notifyViaSMS
          : notifyViaSMS // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyViaCall: null == notifyViaCall
          ? _value.notifyViaCall
          : notifyViaCall // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyViaApp: null == notifyViaApp
          ? _value.notifyViaApp
          : notifyViaApp // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EmergencyContactModelImplCopyWith<$Res>
    implements $EmergencyContactModelCopyWith<$Res> {
  factory _$$EmergencyContactModelImplCopyWith(
          _$EmergencyContactModelImpl value,
          $Res Function(_$EmergencyContactModelImpl) then) =
      __$$EmergencyContactModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String userId,
      @HiveField(2) String name,
      @HiveField(3) String phoneNumber,
      @HiveField(4) String relationship,
      @HiveField(5) int priority,
      @HiveField(6) bool notifyViaSMS,
      @HiveField(7) bool notifyViaCall,
      @HiveField(8) bool notifyViaApp,
      @HiveField(9) DateTime createdAt,
      @HiveField(10) DateTime? updatedAt});
}

/// @nodoc
class __$$EmergencyContactModelImplCopyWithImpl<$Res>
    extends _$EmergencyContactModelCopyWithImpl<$Res,
        _$EmergencyContactModelImpl>
    implements _$$EmergencyContactModelImplCopyWith<$Res> {
  __$$EmergencyContactModelImplCopyWithImpl(_$EmergencyContactModelImpl _value,
      $Res Function(_$EmergencyContactModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? phoneNumber = null,
    Object? relationship = null,
    Object? priority = null,
    Object? notifyViaSMS = null,
    Object? notifyViaCall = null,
    Object? notifyViaApp = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$EmergencyContactModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      relationship: null == relationship
          ? _value.relationship
          : relationship // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      notifyViaSMS: null == notifyViaSMS
          ? _value.notifyViaSMS
          : notifyViaSMS // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyViaCall: null == notifyViaCall
          ? _value.notifyViaCall
          : notifyViaCall // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyViaApp: null == notifyViaApp
          ? _value.notifyViaApp
          : notifyViaApp // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EmergencyContactModelImpl implements _EmergencyContactModel {
  const _$EmergencyContactModelImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.userId,
      @HiveField(2) required this.name,
      @HiveField(3) required this.phoneNumber,
      @HiveField(4) required this.relationship,
      @HiveField(5) this.priority = 1,
      @HiveField(6) this.notifyViaSMS = true,
      @HiveField(7) this.notifyViaCall = false,
      @HiveField(8) this.notifyViaApp = true,
      @HiveField(9) required this.createdAt,
      @HiveField(10) this.updatedAt});

  factory _$EmergencyContactModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmergencyContactModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String userId;
  @override
  @HiveField(2)
  final String name;
  @override
  @HiveField(3)
  final String phoneNumber;
  @override
  @HiveField(4)
  final String relationship;
  @override
  @JsonKey()
  @HiveField(5)
  final int priority;
// 1-5
  @override
  @JsonKey()
  @HiveField(6)
  final bool notifyViaSMS;
  @override
  @JsonKey()
  @HiveField(7)
  final bool notifyViaCall;
  @override
  @JsonKey()
  @HiveField(8)
  final bool notifyViaApp;
  @override
  @HiveField(9)
  final DateTime createdAt;
  @override
  @HiveField(10)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'EmergencyContactModel(id: $id, userId: $userId, name: $name, phoneNumber: $phoneNumber, relationship: $relationship, priority: $priority, notifyViaSMS: $notifyViaSMS, notifyViaCall: $notifyViaCall, notifyViaApp: $notifyViaApp, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmergencyContactModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.relationship, relationship) ||
                other.relationship == relationship) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.notifyViaSMS, notifyViaSMS) ||
                other.notifyViaSMS == notifyViaSMS) &&
            (identical(other.notifyViaCall, notifyViaCall) ||
                other.notifyViaCall == notifyViaCall) &&
            (identical(other.notifyViaApp, notifyViaApp) ||
                other.notifyViaApp == notifyViaApp) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      name,
      phoneNumber,
      relationship,
      priority,
      notifyViaSMS,
      notifyViaCall,
      notifyViaApp,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EmergencyContactModelImplCopyWith<_$EmergencyContactModelImpl>
      get copyWith => __$$EmergencyContactModelImplCopyWithImpl<
          _$EmergencyContactModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EmergencyContactModelImplToJson(
      this,
    );
  }
}

abstract class _EmergencyContactModel implements EmergencyContactModel {
  const factory _EmergencyContactModel(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String userId,
      @HiveField(2) required final String name,
      @HiveField(3) required final String phoneNumber,
      @HiveField(4) required final String relationship,
      @HiveField(5) final int priority,
      @HiveField(6) final bool notifyViaSMS,
      @HiveField(7) final bool notifyViaCall,
      @HiveField(8) final bool notifyViaApp,
      @HiveField(9) required final DateTime createdAt,
      @HiveField(10) final DateTime? updatedAt}) = _$EmergencyContactModelImpl;

  factory _EmergencyContactModel.fromJson(Map<String, dynamic> json) =
      _$EmergencyContactModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get userId;
  @override
  @HiveField(2)
  String get name;
  @override
  @HiveField(3)
  String get phoneNumber;
  @override
  @HiveField(4)
  String get relationship;
  @override
  @HiveField(5)
  int get priority;
  @override // 1-5
  @HiveField(6)
  bool get notifyViaSMS;
  @override
  @HiveField(7)
  bool get notifyViaCall;
  @override
  @HiveField(8)
  bool get notifyViaApp;
  @override
  @HiveField(9)
  DateTime get createdAt;
  @override
  @HiveField(10)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$EmergencyContactModelImplCopyWith<_$EmergencyContactModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
