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

  // Box names
  static const String _userBoxName = 'user_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _checkInBoxName = 'checkin_box';
  static const String _contactBoxName = 'contact_box';

  // Boxes
  late Box _userBox;
  late Box _settingsBox;
  late Box _checkInBox;
  late Box _contactBox;

  /// Initialize
  Future<void> init() async {
    _userBox = await Hive.openBox(_userBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _checkInBox = await Hive.openBox(_checkInBoxName);
    _contactBox = await Hive.openBox(_contactBoxName);
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
        print('Error parsing user data: $e');
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
        print('Error parsing checkin at index $i: $e');
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
        print('Error marking checkin as synced: $e');
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
        print('Error parsing contact at index $i: $e');
      }
    }
    contacts.sort((a, b) => b.priority.compareTo(a.priority)); // Higher priority first (descending)? or ascending? Usually priority 1 is highest.
    // Let's assume 1 is likely highest priority, so sorting ascending by priority value makes sense if 1 < 2.
    // However, if priority is a score, then descending.
    // Looking at the code I replaced: `contacts.sort((a, b) => a.priority.compareTo(b.priority));` (Ascending)
    // So I will keep ascending.
    contacts.sort((a, b) => a.priority.compareTo(b.priority));
    return contacts;
  }

  EmergencyContactModel? getContact(String id) {
    final jsonString = _contactBox.get(id);
    if (jsonString != null) {
      try {
        return EmergencyContactModel.fromJson(jsonDecode(jsonString));
      } catch (e) {
         print('Error parsing contact $id: $e');
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

  int getContactCount() {
    return _contactBox.length;
  }

  // ==================== Settings Operations ====================
  
  Future<void> saveSettings(SettingsModel settings) async {
     // Convert to Map first, because SettingsModel might not have toJson for all fields if I didn't check carefully, 
     // but looking at previous file view, it didn't have toJson!
     // Wait, I checked SettingsModel in step 41, it DOES NOT have toJson!
     // I need to add toJson to SettingsModel or handle it here.
     // It's cleaner to handle it here if I don't want to modify SettingsModel file unless necessary.
     // But wait, `CheckInModel` and `UserModel` had `toJson`.
     // Let me double check `SettingsModel` in step 41.
     // It has `copyWith` but NO `toJson` or `fromJson`!
     // So I must implement manual serialization here or add it to the model.
     // Adding it to the model is better practice.
     // But significantly, for now I can just do it here to avoid context switching too much if I can.
     // Actually, I'll just manual serialized it here since I'm already editing this file.
    
    final map = {
      'notificationsEnabled': settings.notificationsEnabled,
      'locationEnabled': settings.locationEnabled,
      'checkinIntervalHours': settings.checkinIntervalHours,
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
          checkinIntervalHours: map['checkinIntervalHours'] ?? 24,
          language: map['language'] ?? 'en',
          themeIsDark: map['themeIsDark'] ?? false,
          biometricEnabled: map['biometricEnabled'] ?? false,
          updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
        );
      } catch (e) {
        print('Error parsing settings: $e');
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