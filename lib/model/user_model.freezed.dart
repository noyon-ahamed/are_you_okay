// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  @HiveField(0)
  String get uid => throw _privateConstructorUsedError;
  @HiveField(1)
  String get phoneNumber => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get email => throw _privateConstructorUsedError;
  @HiveField(3)
  String get name => throw _privateConstructorUsedError;
  @HiveField(4)
  String? get profilePicture => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime? get dateOfBirth => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get gender => throw _privateConstructorUsedError;
  @HiveField(7)
  String get language => throw _privateConstructorUsedError;
  @HiveField(8)
  int get checkinInterval => throw _privateConstructorUsedError; // hours
  @HiveField(9)
  bool get isActive => throw _privateConstructorUsedError;
  @HiveField(10)
  bool get isPremium => throw _privateConstructorUsedError;
  @HiveField(11)
  String? get address => throw _privateConstructorUsedError;
  @HiveField(12)
  String? get bloodGroup => throw _privateConstructorUsedError;
  @HiveField(13)
  String? get medicalInfo => throw _privateConstructorUsedError;
  @HiveField(14)
  DateTime? get lastCheckIn => throw _privateConstructorUsedError;
  @HiveField(15)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(16)
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String phoneNumber,
      @HiveField(2) String? email,
      @HiveField(3) String name,
      @HiveField(4) String? profilePicture,
      @HiveField(5) DateTime? dateOfBirth,
      @HiveField(6) String? gender,
      @HiveField(7) String language,
      @HiveField(8) int checkinInterval,
      @HiveField(9) bool isActive,
      @HiveField(10) bool isPremium,
      @HiveField(11) String? address,
      @HiveField(12) String? bloodGroup,
      @HiveField(13) String? medicalInfo,
      @HiveField(14) DateTime? lastCheckIn,
      @HiveField(15) DateTime createdAt,
      @HiveField(16) DateTime updatedAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? phoneNumber = null,
    Object? email = freezed,
    Object? name = null,
    Object? profilePicture = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? language = null,
    Object? checkinInterval = null,
    Object? isActive = null,
    Object? isPremium = null,
    Object? address = freezed,
    Object? bloodGroup = freezed,
    Object? medicalInfo = freezed,
    Object? lastCheckIn = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      profilePicture: freezed == profilePicture
          ? _value.profilePicture
          : profilePicture // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      checkinInterval: null == checkinInterval
          ? _value.checkinInterval
          : checkinInterval // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      bloodGroup: freezed == bloodGroup
          ? _value.bloodGroup
          : bloodGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      medicalInfo: freezed == medicalInfo
          ? _value.medicalInfo
          : medicalInfo // ignore: cast_nullable_to_non_nullable
              as String?,
      lastCheckIn: freezed == lastCheckIn
          ? _value.lastCheckIn
          : lastCheckIn // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String phoneNumber,
      @HiveField(2) String? email,
      @HiveField(3) String name,
      @HiveField(4) String? profilePicture,
      @HiveField(5) DateTime? dateOfBirth,
      @HiveField(6) String? gender,
      @HiveField(7) String language,
      @HiveField(8) int checkinInterval,
      @HiveField(9) bool isActive,
      @HiveField(10) bool isPremium,
      @HiveField(11) String? address,
      @HiveField(12) String? bloodGroup,
      @HiveField(13) String? medicalInfo,
      @HiveField(14) DateTime? lastCheckIn,
      @HiveField(15) DateTime createdAt,
      @HiveField(16) DateTime updatedAt});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? phoneNumber = null,
    Object? email = freezed,
    Object? name = null,
    Object? profilePicture = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? language = null,
    Object? checkinInterval = null,
    Object? isActive = null,
    Object? isPremium = null,
    Object? address = freezed,
    Object? bloodGroup = freezed,
    Object? medicalInfo = freezed,
    Object? lastCheckIn = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$UserModelImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      profilePicture: freezed == profilePicture
          ? _value.profilePicture
          : profilePicture // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      checkinInterval: null == checkinInterval
          ? _value.checkinInterval
          : checkinInterval // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      bloodGroup: freezed == bloodGroup
          ? _value.bloodGroup
          : bloodGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      medicalInfo: freezed == medicalInfo
          ? _value.medicalInfo
          : medicalInfo // ignore: cast_nullable_to_non_nullable
              as String?,
      lastCheckIn: freezed == lastCheckIn
          ? _value.lastCheckIn
          : lastCheckIn // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {@HiveField(0) required this.uid,
      @HiveField(1) required this.phoneNumber,
      @HiveField(2) this.email,
      @HiveField(3) required this.name,
      @HiveField(4) this.profilePicture,
      @HiveField(5) this.dateOfBirth,
      @HiveField(6) this.gender,
      @HiveField(7) this.language = 'bn',
      @HiveField(8) this.checkinInterval = 48,
      @HiveField(9) this.isActive = true,
      @HiveField(10) this.isPremium = false,
      @HiveField(11) this.address,
      @HiveField(12) this.bloodGroup,
      @HiveField(13) this.medicalInfo,
      @HiveField(14) this.lastCheckIn,
      @HiveField(15) required this.createdAt,
      @HiveField(16) required this.updatedAt});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  @HiveField(0)
  final String uid;
  @override
  @HiveField(1)
  final String phoneNumber;
  @override
  @HiveField(2)
  final String? email;
  @override
  @HiveField(3)
  final String name;
  @override
  @HiveField(4)
  final String? profilePicture;
  @override
  @HiveField(5)
  final DateTime? dateOfBirth;
  @override
  @HiveField(6)
  final String? gender;
  @override
  @JsonKey()
  @HiveField(7)
  final String language;
  @override
  @JsonKey()
  @HiveField(8)
  final int checkinInterval;
// hours
  @override
  @JsonKey()
  @HiveField(9)
  final bool isActive;
  @override
  @JsonKey()
  @HiveField(10)
  final bool isPremium;
  @override
  @HiveField(11)
  final String? address;
  @override
  @HiveField(12)
  final String? bloodGroup;
  @override
  @HiveField(13)
  final String? medicalInfo;
  @override
  @HiveField(14)
  final DateTime? lastCheckIn;
  @override
  @HiveField(15)
  final DateTime createdAt;
  @override
  @HiveField(16)
  final DateTime updatedAt;

  @override
  String toString() {
    return 'UserModel(uid: $uid, phoneNumber: $phoneNumber, email: $email, name: $name, profilePicture: $profilePicture, dateOfBirth: $dateOfBirth, gender: $gender, language: $language, checkinInterval: $checkinInterval, isActive: $isActive, isPremium: $isPremium, address: $address, bloodGroup: $bloodGroup, medicalInfo: $medicalInfo, lastCheckIn: $lastCheckIn, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.profilePicture, profilePicture) ||
                other.profilePicture == profilePicture) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.checkinInterval, checkinInterval) ||
                other.checkinInterval == checkinInterval) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.bloodGroup, bloodGroup) ||
                other.bloodGroup == bloodGroup) &&
            (identical(other.medicalInfo, medicalInfo) ||
                other.medicalInfo == medicalInfo) &&
            (identical(other.lastCheckIn, lastCheckIn) ||
                other.lastCheckIn == lastCheckIn) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uid,
      phoneNumber,
      email,
      name,
      profilePicture,
      dateOfBirth,
      gender,
      language,
      checkinInterval,
      isActive,
      isPremium,
      address,
      bloodGroup,
      medicalInfo,
      lastCheckIn,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {@HiveField(0) required final String uid,
      @HiveField(1) required final String phoneNumber,
      @HiveField(2) final String? email,
      @HiveField(3) required final String name,
      @HiveField(4) final String? profilePicture,
      @HiveField(5) final DateTime? dateOfBirth,
      @HiveField(6) final String? gender,
      @HiveField(7) final String language,
      @HiveField(8) final int checkinInterval,
      @HiveField(9) final bool isActive,
      @HiveField(10) final bool isPremium,
      @HiveField(11) final String? address,
      @HiveField(12) final String? bloodGroup,
      @HiveField(13) final String? medicalInfo,
      @HiveField(14) final DateTime? lastCheckIn,
      @HiveField(15) required final DateTime createdAt,
      @HiveField(16) required final DateTime updatedAt}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  @HiveField(0)
  String get uid;
  @override
  @HiveField(1)
  String get phoneNumber;
  @override
  @HiveField(2)
  String? get email;
  @override
  @HiveField(3)
  String get name;
  @override
  @HiveField(4)
  String? get profilePicture;
  @override
  @HiveField(5)
  DateTime? get dateOfBirth;
  @override
  @HiveField(6)
  String? get gender;
  @override
  @HiveField(7)
  String get language;
  @override
  @HiveField(8)
  int get checkinInterval;
  @override // hours
  @HiveField(9)
  bool get isActive;
  @override
  @HiveField(10)
  bool get isPremium;
  @override
  @HiveField(11)
  String? get address;
  @override
  @HiveField(12)
  String? get bloodGroup;
  @override
  @HiveField(13)
  String? get medicalInfo;
  @override
  @HiveField(14)
  DateTime? get lastCheckIn;
  @override
  @HiveField(15)
  DateTime get createdAt;
  @override
  @HiveField(16)
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
