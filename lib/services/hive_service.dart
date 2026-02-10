import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../model/checkin_model.dart';
import '../model/emergency_contact_model.dart';
import '../model/settings_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // In-memory storage
  UserModel? _currentUser;
  final Map<String, CheckInModel> _checkIns = {};
  final Map<String, EmergencyContactModel> _contacts = {};
  SettingsModel _settings = const SettingsModel();

  /// Initialize
  Future<void> init() async {
    // No-op
  }

  // ==================== User Operations ====================
  
  Future<void> saveUser(UserModel user) async {
    _currentUser = user;
  }

  UserModel? getCurrentUser() {
    return _currentUser;
  }

  Future<void> deleteUser() async {
    _currentUser = null;
  }

  Future<void> updateUser(UserModel user) async {
    _currentUser = user;
  }

  // ==================== Check-in Operations ====================
  
  Future<void> saveCheckIn(CheckInModel checkIn) async {
    _checkIns[checkIn.id] = checkIn;
  }

  List<CheckInModel> getAllCheckIns() {
    return _checkIns.values.toList();
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
    _checkIns.remove(id);
  }

  List<CheckInModel> getPendingSyncCheckIns() {
    return _checkIns.values.where((c) => !c.isSynced).toList();
  }

  Future<void> markCheckInAsSynced(String id) async {
    final checkIn = _checkIns[id];
    if (checkIn != null) {
      _checkIns[id] = checkIn.copyWith(isSynced: true);
    }
  }

  // ==================== Emergency Contact Operations ====================
  
  Future<void> saveContact(EmergencyContactModel contact) async {
    _contacts[contact.id] = contact;
  }

  List<EmergencyContactModel> getAllContacts() {
    final contacts = _contacts.values.toList();
    contacts.sort((a, b) => a.priority.compareTo(b.priority));
    return contacts;
  }

  EmergencyContactModel? getContact(String id) {
    return _contacts[id];
  }

  Future<void> updateContact(EmergencyContactModel contact) async {
    _contacts[contact.id] = contact;
  }

  Future<void> deleteContact(String id) async {
    _contacts.remove(id);
  }

  int getContactCount() {
    return _contacts.length;
  }

  // ==================== Settings Operations ====================
  
  Future<void> saveSettings(SettingsModel settings) async {
    _settings = settings;
  }

  SettingsModel getSettings() {
    return _settings;
  }

  Future<void> updateSettings(SettingsModel settings) async {
    _settings = settings;
  }

  // ==================== Clear All Data ====================
  
  Future<void> clearAllData() async {
    _currentUser = null;
    _checkIns.clear();
    _contacts.clear();
    _settings = const SettingsModel();
  }

  Future<void> close() async {
    // No-op
  }
}