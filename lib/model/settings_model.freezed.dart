// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) {
  return _SettingsModel.fromJson(json);
}

/// @nodoc
mixin _$SettingsModel {
  @HiveField(0)
  String get language => throw _privateConstructorUsedError;
  @HiveField(1)
  String get themeMode =>
      throw _privateConstructorUsedError; // light, dark, system
  @HiveField(2)
  bool get notificationsEnabled => throw _privateConstructorUsedError;
  @HiveField(3)
  bool get reminderNotifications => throw _privateConstructorUsedError;
  @HiveField(4)
  bool get alertNotifications => throw _privateConstructorUsedError;
  @HiveField(5)
  int get checkinIntervalHours => throw _privateConstructorUsedError;
  @HiveField(6)
  bool get locationEnabled => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get soundEnabled => throw _privateConstructorUsedError;
  @HiveField(8)
  bool get vibrationEnabled => throw _privateConstructorUsedError;
  @HiveField(9)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SettingsModelCopyWith<SettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsModelCopyWith<$Res> {
  factory $SettingsModelCopyWith(
          SettingsModel value, $Res Function(SettingsModel) then) =
      _$SettingsModelCopyWithImpl<$Res, SettingsModel>;
  @useResult
  $Res call(
      {@HiveField(0) String language,
      @HiveField(1) String themeMode,
      @HiveField(2) bool notificationsEnabled,
      @HiveField(3) bool reminderNotifications,
      @HiveField(4) bool alertNotifications,
      @HiveField(5) int checkinIntervalHours,
      @HiveField(6) bool locationEnabled,
      @HiveField(7) bool soundEnabled,
      @HiveField(8) bool vibrationEnabled,
      @HiveField(9) DateTime? updatedAt});
}

/// @nodoc
class _$SettingsModelCopyWithImpl<$Res, $Val extends SettingsModel>
    implements $SettingsModelCopyWith<$Res> {
  _$SettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? themeMode = null,
    Object? notificationsEnabled = null,
    Object? reminderNotifications = null,
    Object? alertNotifications = null,
    Object? checkinIntervalHours = null,
    Object? locationEnabled = null,
    Object? soundEnabled = null,
    Object? vibrationEnabled = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderNotifications: null == reminderNotifications
          ? _value.reminderNotifications
          : reminderNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      alertNotifications: null == alertNotifications
          ? _value.alertNotifications
          : alertNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      checkinIntervalHours: null == checkinIntervalHours
          ? _value.checkinIntervalHours
          : checkinIntervalHours // ignore: cast_nullable_to_non_nullable
              as int,
      locationEnabled: null == locationEnabled
          ? _value.locationEnabled
          : locationEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      soundEnabled: null == soundEnabled
          ? _value.soundEnabled
          : soundEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      vibrationEnabled: null == vibrationEnabled
          ? _value.vibrationEnabled
          : vibrationEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SettingsModelImplCopyWith<$Res>
    implements $SettingsModelCopyWith<$Res> {
  factory _$$SettingsModelImplCopyWith(
          _$SettingsModelImpl value, $Res Function(_$SettingsModelImpl) then) =
      __$$SettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String language,
      @HiveField(1) String themeMode,
      @HiveField(2) bool notificationsEnabled,
      @HiveField(3) bool reminderNotifications,
      @HiveField(4) bool alertNotifications,
      @HiveField(5) int checkinIntervalHours,
      @HiveField(6) bool locationEnabled,
      @HiveField(7) bool soundEnabled,
      @HiveField(8) bool vibrationEnabled,
      @HiveField(9) DateTime? updatedAt});
}

/// @nodoc
class __$$SettingsModelImplCopyWithImpl<$Res>
    extends _$SettingsModelCopyWithImpl<$Res, _$SettingsModelImpl>
    implements _$$SettingsModelImplCopyWith<$Res> {
  __$$SettingsModelImplCopyWithImpl(
      _$SettingsModelImpl _value, $Res Function(_$SettingsModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? themeMode = null,
    Object? notificationsEnabled = null,
    Object? reminderNotifications = null,
    Object? alertNotifications = null,
    Object? checkinIntervalHours = null,
    Object? locationEnabled = null,
    Object? soundEnabled = null,
    Object? vibrationEnabled = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$SettingsModelImpl(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderNotifications: null == reminderNotifications
          ? _value.reminderNotifications
          : reminderNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      alertNotifications: null == alertNotifications
          ? _value.alertNotifications
          : alertNotifications // ignore: cast_nullable_to_non_nullable
              as bool,
      checkinIntervalHours: null == checkinIntervalHours
          ? _value.checkinIntervalHours
          : checkinIntervalHours // ignore: cast_nullable_to_non_nullable
              as int,
      locationEnabled: null == locationEnabled
          ? _value.locationEnabled
          : locationEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      soundEnabled: null == soundEnabled
          ? _value.soundEnabled
          : soundEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      vibrationEnabled: null == vibrationEnabled
          ? _value.vibrationEnabled
          : vibrationEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SettingsModelImpl implements _SettingsModel {
  const _$SettingsModelImpl(
      {@HiveField(0) this.language = 'bn',
      @HiveField(1) this.themeMode = 'system',
      @HiveField(2) this.notificationsEnabled = true,
      @HiveField(3) this.reminderNotifications = true,
      @HiveField(4) this.alertNotifications = true,
      @HiveField(5) this.checkinIntervalHours = 48,
      @HiveField(6) this.locationEnabled = true,
      @HiveField(7) this.soundEnabled = false,
      @HiveField(8) this.vibrationEnabled = true,
      @HiveField(9) this.updatedAt});

  factory _$SettingsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SettingsModelImplFromJson(json);

  @override
  @JsonKey()
  @HiveField(0)
  final String language;
  @override
  @JsonKey()
  @HiveField(1)
  final String themeMode;
// light, dark, system
  @override
  @JsonKey()
  @HiveField(2)
  final bool notificationsEnabled;
  @override
  @JsonKey()
  @HiveField(3)
  final bool reminderNotifications;
  @override
  @JsonKey()
  @HiveField(4)
  final bool alertNotifications;
  @override
  @JsonKey()
  @HiveField(5)
  final int checkinIntervalHours;
  @override
  @JsonKey()
  @HiveField(6)
  final bool locationEnabled;
  @override
  @JsonKey()
  @HiveField(7)
  final bool soundEnabled;
  @override
  @JsonKey()
  @HiveField(8)
  final bool vibrationEnabled;
  @override
  @HiveField(9)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SettingsModel(language: $language, themeMode: $themeMode, notificationsEnabled: $notificationsEnabled, reminderNotifications: $reminderNotifications, alertNotifications: $alertNotifications, checkinIntervalHours: $checkinIntervalHours, locationEnabled: $locationEnabled, soundEnabled: $soundEnabled, vibrationEnabled: $vibrationEnabled, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsModelImpl &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled) &&
            (identical(other.reminderNotifications, reminderNotifications) ||
                other.reminderNotifications == reminderNotifications) &&
            (identical(other.alertNotifications, alertNotifications) ||
                other.alertNotifications == alertNotifications) &&
            (identical(other.checkinIntervalHours, checkinIntervalHours) ||
                other.checkinIntervalHours == checkinIntervalHours) &&
            (identical(other.locationEnabled, locationEnabled) ||
                other.locationEnabled == locationEnabled) &&
            (identical(other.soundEnabled, soundEnabled) ||
                other.soundEnabled == soundEnabled) &&
            (identical(other.vibrationEnabled, vibrationEnabled) ||
                other.vibrationEnabled == vibrationEnabled) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      language,
      themeMode,
      notificationsEnabled,
      reminderNotifications,
      alertNotifications,
      checkinIntervalHours,
      locationEnabled,
      soundEnabled,
      vibrationEnabled,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsModelImplCopyWith<_$SettingsModelImpl> get copyWith =>
      __$$SettingsModelImplCopyWithImpl<_$SettingsModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SettingsModelImplToJson(
      this,
    );
  }
}

abstract class _SettingsModel implements SettingsModel {
  const factory _SettingsModel(
      {@HiveField(0) final String language,
      @HiveField(1) final String themeMode,
      @HiveField(2) final bool notificationsEnabled,
      @HiveField(3) final bool reminderNotifications,
      @HiveField(4) final bool alertNotifications,
      @HiveField(5) final int checkinIntervalHours,
      @HiveField(6) final bool locationEnabled,
      @HiveField(7) final bool soundEnabled,
      @HiveField(8) final bool vibrationEnabled,
      @HiveField(9) final DateTime? updatedAt}) = _$SettingsModelImpl;

  factory _SettingsModel.fromJson(Map<String, dynamic> json) =
      _$SettingsModelImpl.fromJson;

  @override
  @HiveField(0)
  String get language;
  @override
  @HiveField(1)
  String get themeMode;
  @override // light, dark, system
  @HiveField(2)
  bool get notificationsEnabled;
  @override
  @HiveField(3)
  bool get reminderNotifications;
  @override
  @HiveField(4)
  bool get alertNotifications;
  @override
  @HiveField(5)
  int get checkinIntervalHours;
  @override
  @HiveField(6)
  bool get locationEnabled;
  @override
  @HiveField(7)
  bool get soundEnabled;
  @override
  @HiveField(8)
  bool get vibrationEnabled;
  @override
  @HiveField(9)
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SettingsModelImplCopyWith<_$SettingsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
