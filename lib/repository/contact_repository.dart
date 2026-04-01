import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/emergency_contact_model.dart';
import '../services/hive_service.dart';
import '../services/api/emergency_api_service.dart';
import '../services/api/config_api_service.dart';
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
  final ConfigApiService _configApi = ConfigApiService();
  final _uuid = const Uuid();

  ContactRepository({required this.hive, required this.api});

  /// Load contacts from backend, cache in Hive
  Future<List<EmergencyContactModel>> loadContactsFromBackend() async {
    try {
      final backendContacts = await api.getContacts();

      // Build the full contacts list from backend data first
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
          notifyViaEmail:
              bc['email'] != null && bc['email'].toString().isNotEmpty,
          notifyViaApp: true,
          createdAt: bc['createdAt'] != null
              ? DateTime.tryParse(bc['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          updatedAt: bc['updatedAt'] != null
              ? DateTime.tryParse(bc['updatedAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );
        contacts.add(contact);
      }

      // Only after we have the full list, upsert into Hive (safe — no data loss)
      // Remove contacts that no longer exist in backend (stale local entries)
      final backendIds = contacts.map((c) => c.id).toSet();
      final currentLocal = hive.getAllContacts();
      for (final c in currentLocal) {
        if (c.id.startsWith('pending_')) {
          continue;
        }
        if (!backendIds.contains(c.id)) {
          await hive.deleteContact(c.id);
        }
      }
      // Save/update all backend contacts into Hive
      for (final contact in contacts) {
        await hive.saveContact(contact);
      }

      contacts.sort((a, b) => a.priority.compareTo(b.priority));
      return contacts;
    } catch (e) {
      debugPrint('Failed to load contacts from backend (offline?): $e');
      // Fallback — return whatever is in local Hive cache (untouched)
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
    final maxContacts = await getMaxEmergencyContacts();
    final currentCount = await _getContactCount();
    if (currentCount >= maxContacts) {
      throw Exception(
        'সর্বোচ্চ $maxContacts টি কন্টাক্ট যোগ করা যায়',
      );
    }

    final backendContact = await api.addContact(
      name: name,
      phone: phoneNumber,
      email: email,
      relation: relationship,
      priority: priority,
    );

    final now = DateTime.now();
    final contact = EmergencyContactModel(
      id: _contactIdFromMap(backendContact),
      userId: backendContact['userId']?.toString() ??
          backendContact['user']?.toString() ??
          hive.getCurrentUser()?.id ??
          '',
      name: backendContact['name']?.toString() ?? name,
      phoneNumber: backendContact['phone']?.toString() ?? phoneNumber,
      email: backendContact['email']?.toString() ?? email,
      relationship: backendContact['relation']?.toString() ?? relationship,
      priority: _priorityFromMap(backendContact, fallback: priority),
      notifyViaSMS: notifyViaSMS,
      notifyViaCall: notifyViaCall,
      notifyViaEmail: notifyViaEmail,
      notifyViaApp: notifyViaApp,
      createdAt: _dateFromMap(backendContact['createdAt']) ?? now,
      updatedAt: _dateFromMap(backendContact['updatedAt']) ?? now,
    );

    await hive.saveContact(contact);
    return contact;
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
  Future<bool> canAddMoreContacts() async {
    final maxContacts = await getMaxEmergencyContacts();
    return getContactCount() < maxContacts;
  }

  Future<int> getMaxEmergencyContacts() async {
    try {
      return await _configApi.getMaxEmergencyContacts();
    } catch (_) {
      return AppConstants.maxEmergencyContacts;
    }
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
          if (contact.id.startsWith('pending_')) continue;
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
        .where((c) =>
            c.notifyViaSMS ||
            c.notifyViaCall ||
            c.notifyViaEmail ||
            c.notifyViaApp)
        .toList();
  }

  String _contactIdFromMap(Map<String, dynamic> contact) {
    return contact['_id']?.toString() ??
        contact['id']?.toString() ??
        _uuid.v4();
  }

  int _priorityFromMap(
    Map<String, dynamic> contact, {
    required int fallback,
  }) {
    final raw = contact['priority'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  DateTime? _dateFromMap(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
