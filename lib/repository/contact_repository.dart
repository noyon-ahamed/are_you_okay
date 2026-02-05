import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/emergency_contact_model.dart';
import '../services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import 'auth_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(
    hive: ref.watch(hiveServiceProvider),
  );
});

class ContactRepository {
  final HiveService hive;
  final _uuid = const Uuid();

  ContactRepository({required this.hive});

  /// Add new emergency contact
  Future<EmergencyContactModel> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
    int priority = 1,
    bool notifyViaSMS = true,
    bool notifyViaCall = false,
    bool notifyViaApp = true,
  }) async {
    try {
      final user = hive.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check max contacts limit
      if (hive.getContactCount() >= AppConstants.maxEmergencyContacts) {
        throw Exception(
          'Maximum ${AppConstants.maxEmergencyContacts} contacts allowed',
        );
      }

      final contact = EmergencyContactModel(
        id: _uuid.v4(),
        userId: user.uid,
        name: name,
        phoneNumber: phoneNumber,
        relationship: relationship,
        priority: priority,
        notifyViaSMS: notifyViaSMS,
        notifyViaCall: notifyViaCall,
        notifyViaApp: notifyViaApp,
        createdAt: DateTime.now(),
      );

      await hive.saveContact(contact);
      
      // TODO: Sync with Firebase

      return contact;
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

  /// Get all contacts
  List<EmergencyContactModel> getAllContacts() {
    return hive.getAllContacts();
  }

  /// Get contact by ID
  EmergencyContactModel? getContact(String id) {
    return hive.getContact(id);
  }

  /// Update contact
  Future<EmergencyContactModel> updateContact(
    EmergencyContactModel contact,
  ) async {
    try {
      final updated = contact.copyWith(updatedAt: DateTime.now());
      await hive.updateContact(updated);
      
      // TODO: Sync with Firebase

      return updated;
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  /// Delete contact
  Future<void> deleteContact(String id) async {
    try {
      await hive.deleteContact(id);
      
      // TODO: Sync with Firebase
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  /// Get contact count
  int getContactCount() {
    return hive.getContactCount();
  }

  /// Check if can add more contacts
  bool canAddMoreContacts() {
    return getContactCount() < AppConstants.maxEmergencyContacts;
  }

  /// Reorder contacts (change priority)
  Future<void> reorderContacts(List<String> orderedIds) async {
    try {
      for (int i = 0; i < orderedIds.length; i++) {
        final contact = hive.getContact(orderedIds[i]);
        if (contact != null) {
          await hive.updateContact(
            contact.copyWith(
              priority: i + 1,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to reorder contacts: $e');
    }
  }

  /// Get contacts for notifications (sorted by priority)
  List<EmergencyContactModel> getNotificationContacts() {
    return getAllContacts()
        .where((c) => c.notifyViaSMS || c.notifyViaCall || c.notifyViaApp)
        .toList();
  }
}