import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/emergency_contact_model.dart';
import '../services/hive_service.dart';
import '../services/api/emergency_api_service.dart';
import '../core/constants/app_constants.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(
    hive: ref.watch(hiveServiceProvider),
    api: EmergencyApiService(),
  );
});

class ContactRepository {
  final HiveService hive;
  final EmergencyApiService api;
  final _uuid = const Uuid();

  ContactRepository({required this.hive, required this.api});

  /// Load contacts from backend, cache in Hive
  Future<List<EmergencyContactModel>> loadContactsFromBackend() async {
    try {
      final backendContacts = await api.getContacts();
      
      // Clear local cache and replace with backend data
      final currentLocal = hive.getAllContacts();
      for (final c in currentLocal) {
        await hive.deleteContact(c.id);
      }

      final List<EmergencyContactModel> contacts = [];
      for (final bc in backendContacts) {
        final contact = EmergencyContactModel(
          id: bc['_id']?.toString() ?? _uuid.v4(),
          userId: bc['userId']?.toString() ?? '',
          name: bc['name']?.toString() ?? '',
          phoneNumber: bc['phone']?.toString() ?? '',
          email: bc['email']?.toString(),
          relationship: bc['relation']?.toString() ?? 'Other',
          priority: bc['priority'] as int? ?? 1,
          notifyViaSMS: true,
          notifyViaCall: false,
          notifyViaEmail: bc['email'] != null && bc['email'].toString().isNotEmpty,
          notifyViaApp: true,
          createdAt: bc['createdAt'] != null
              ? DateTime.tryParse(bc['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          updatedAt: bc['updatedAt'] != null
              ? DateTime.tryParse(bc['updatedAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );
        await hive.saveContact(contact);
        contacts.add(contact);
      }

      contacts.sort((a, b) => a.priority.compareTo(b.priority));
      return contacts;
    } catch (e) {
      debugPrint('Failed to load contacts from backend: $e');
      // Fallback to local data
      return hive.getAllContacts();
    }
  }

  /// Add new emergency contact — saves to backend first, then caches locally
  Future<EmergencyContactModel> addContact({
    required String name,
    required String phoneNumber,
    String? email,
    required String relationship,
    int priority = 1,
    bool notifyViaSMS = true,
    bool notifyViaCall = false,
    bool notifyViaEmail = true,
    bool notifyViaApp = true,
  }) async {
    // Check max contacts limit
    final currentCount = await _getContactCount();
    if (currentCount >= AppConstants.maxEmergencyContacts) {
      throw Exception(
        'সর্বোচ্চ ${AppConstants.maxEmergencyContacts}টি কন্টাক্ট যোগ করা যায়',
      );
    }

    try {
      // Save to backend first
      final backendContact = await api.addContact(
        name: name,
        phone: phoneNumber,
        email: email,
        relation: relationship,
        priority: priority,
      );

      final contact = EmergencyContactModel(
        id: backendContact['_id']?.toString() ?? _uuid.v4(),
        userId: backendContact['userId']?.toString() ?? '',
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        relationship: relationship,
        priority: backendContact['priority'] as int? ?? priority,
        notifyViaSMS: notifyViaSMS,
        notifyViaCall: notifyViaCall,
        notifyViaEmail: notifyViaEmail,
        notifyViaApp: notifyViaApp,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Cache locally
      await hive.saveContact(contact);
      return contact;
    } catch (e) {
      // If backend fails, still save locally
      debugPrint('Backend addContact failed, saving locally: $e');
      final user = hive.getCurrentUser();
      final contact = EmergencyContactModel(
        id: _uuid.v4(),
        userId: user?.id ?? 'offline',
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        relationship: relationship,
        priority: priority,
        notifyViaSMS: notifyViaSMS,
        notifyViaCall: notifyViaCall,
        notifyViaEmail: notifyViaEmail,
        notifyViaApp: notifyViaApp,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await hive.saveContact(contact);
      rethrow;
    }
  }

  /// Get all contacts (from local cache)
  List<EmergencyContactModel> getAllContacts() {
    return hive.getAllContacts();
  }

  /// Get contact by ID
  EmergencyContactModel? getContact(String id) {
    return hive.getContact(id);
  }

  /// Update contact — updates backend first, then local cache
  Future<EmergencyContactModel> updateContact(
    EmergencyContactModel contact,
  ) async {
    try {
      await api.updateContact(
        id: contact.id,
        name: contact.name,
        phone: contact.phoneNumber,
        email: contact.email,
        relation: contact.relationship,
        priority: contact.priority,
      );
    } catch (e) {
      debugPrint('Backend updateContact failed: $e');
    }

    final updated = contact.copyWith(updatedAt: DateTime.now());
    await hive.updateContact(updated);
    return updated;
  }

  /// Delete contact — deletes from backend first, then local
  Future<void> deleteContact(String id) async {
    try {
      await api.deleteContact(id);
    } catch (e) {
      debugPrint('Backend deleteContact failed: $e');
    }

    await hive.deleteContact(id);
  }

  /// Get contact count
  Future<int> _getContactCount() async {
    try {
      final backendContacts = await api.getContacts();
      return backendContacts.length;
    } catch (e) {
      return hive.getContactCount();
    }
  }

  /// Get contact count (sync)
  int getContactCount() {
    return hive.getContactCount();
  }

  /// Check if can add more contacts
  bool canAddMoreContacts() {
    return getContactCount() < AppConstants.maxEmergencyContacts;
  }

  /// Reorder contacts (change priority) — updates backend for each
  Future<void> reorderContacts(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final contact = hive.getContact(orderedIds[i]);
      if (contact != null) {
        final updated = contact.copyWith(
          priority: i + 1,
          updatedAt: DateTime.now(),
        );
        await hive.updateContact(updated);

        // Update backend priority
        try {
          await api.updateContact(
            id: contact.id,
            priority: i + 1,
          );
        } catch (e) {
          debugPrint('Backend reorder failed for ${contact.id}: $e');
        }
      }
    }
  }

  /// Get contacts for notifications (sorted by priority)
  List<EmergencyContactModel> getNotificationContacts() {
    return getAllContacts()
        .where((c) => c.notifyViaSMS || c.notifyViaCall || c.notifyViaEmail || c.notifyViaApp)
        .toList();
  }
}