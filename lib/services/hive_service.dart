import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/user_model.dart';
import '../model/checkin_model.dart';
import '../model/emergency_contact_model.dart';
import '../model/settings_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _userBoxName = 'user_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _checkInBoxName = 'checkin_box';
  static const String _contactBoxName = 'contact_box';

  late Box _userBox;
  late Box _settingsBox;
  late Box _checkInBox;
  late Box _contactBox;

  Future<void> init() async {
    final results = await Future.wait([
      Hive.openBox(_userBoxName),
      Hive.openBox(_settingsBoxName),
      Hive.openBox(_checkInBoxName),
      Hive.openBox(_contactBoxName),
    ]);
    _userBox = results[0];
    _settingsBox = results[1];
    _checkInBox = results[2];
    _contactBox = results[3];
  }

  // ==================== User Operations ====================

  Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', jsonEncode(user.toJson()));
  }

  UserModel? getCurrentUser() {
    final userJson = _userBox.get('current_user');
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _userBox.delete('current_user');
  }

  Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  // ==================== Check-in Operations ====================

  Future<void> saveCheckIn(CheckInModel checkIn) async {
    await _checkInBox.put(checkIn.id, jsonEncode(checkIn.toJson()));
  }

  List<CheckInModel> getAllCheckIns() {
    final List<CheckInModel> checkIns = [];
    for (var i = 0; i < _checkInBox.length; i++) {
      try {
        final jsonString = _checkInBox.getAt(i);
        if (jsonString != null) {
          checkIns.add(CheckInModel.fromJson(jsonDecode(jsonString)));
        }
      } catch (e) {
        // skip
      }
    }
    return checkIns;
  }

  List<CheckInModel> getRecentCheckIns({int limit = 10}) {
    final all = getAllCheckIns();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }

  CheckInModel? getLastCheckIn() {
    final recent = getRecentCheckIns(limit: 1);
    return recent.isNotEmpty ? recent.first : null;
  }

  Future<void> deleteCheckIn(String id) async {
    await _checkInBox.delete(id);
  }

  List<CheckInModel> getPendingSyncCheckIns() {
    return getAllCheckIns().where((c) => !c.isSynced).toList();
  }

  Future<void> markCheckInAsSynced(String id) async {
    final jsonString = _checkInBox.get(id);
    if (jsonString != null) {
      try {
        final checkIn = CheckInModel.fromJson(jsonDecode(jsonString));
        final updated = checkIn.copyWith(isSynced: true);
        await saveCheckIn(updated);
      } catch (e) {
        // skip
      }
    }
  }

  // ==================== Emergency Contact Operations ====================

  Future<void> saveContact(EmergencyContactModel contact) async {
    await _contactBox.put(contact.id, jsonEncode(contact.toJson()));
  }

  List<EmergencyContactModel> getAllContacts() {
    final List<EmergencyContactModel> contacts = [];
    for (var i = 0; i < _contactBox.length; i++) {
      try {
        final jsonString = _contactBox.getAt(i);
        if (jsonString != null) {
          contacts.add(EmergencyContactModel.fromJson(jsonDecode(jsonString)));
        }
      } catch (e) {
        // skip
      }
    }
    contacts.sort((a, b) => a.priority.compareTo(b.priority));
    return contacts;
  }

  EmergencyContactModel? getContact(String id) {
    final jsonString = _contactBox.get(id);
    if (jsonString != null) {
      try {
        return EmergencyContactModel.fromJson(jsonDecode(jsonString));
      } catch (e) {
        // skip
      }
    }
    return null;
  }

  Future<void> updateContact(EmergencyContactModel contact) async {
    await saveContact(contact);
  }

  Future<void> deleteContact(String id) async {
    await _contactBox.delete(id);
  }

  Future<void> clearContacts() async {
    await _contactBox.clear();
  }

  int getContactCount() {
    return _contactBox.length;
  }

  // ==================== Settings Operations ====================

  Future<void> saveSettings(SettingsModel settings) async {
    final map = {
      'notificationsEnabled': settings.notificationsEnabled,
      'locationEnabled': settings.locationEnabled,
      'checkinIntervalDays': settings.checkinIntervalDays,
      'language': settings.language,
      'themeIsDark': settings.themeIsDark,
      'biometricEnabled': settings.biometricEnabled,
      'updatedAt': settings.updatedAt?.toIso8601String(),
    };
    await _settingsBox.put('settings', jsonEncode(map));
  }

  SettingsModel getSettings() {
    final jsonString = _settingsBox.get('settings');
    if (jsonString != null) {
      try {
        final map = jsonDecode(jsonString);
        return SettingsModel(
          notificationsEnabled: map['notificationsEnabled'] ?? true,
          locationEnabled: map['locationEnabled'] ?? true,
          checkinIntervalDays: map['checkinIntervalDays'] ?? 3,
          language: map['language'] ?? 'en',
          themeIsDark: map['themeIsDark'] ?? false,
          biometricEnabled: map['biometricEnabled'] ?? false,
          updatedAt: map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'])
              : null,
        );
      } catch (e) {
        return const SettingsModel();
      }
    }
    return const SettingsModel();
  }

  Future<void> updateSettings(SettingsModel settings) async {
    await saveSettings(settings);
  }

  // ==================== Clear All Data ====================

  Future<void> clearAllData() async {
    await _userBox.clear();
    await _checkInBox.clear();
    await _contactBox.clear();
    await _settingsBox.clear();
  }

  Future<void> close() async {
    await _userBox.close();
    await _settingsBox.close();
    await _checkInBox.close();
    await _contactBox.close();
  }
}
