import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../model/emergency_contact_model.dart';
import '../auth/token_storage_service.dart';
import '../hive_service.dart';
import 'session_guard.dart';

const String _kPendingContactsKey = 'pending_contacts_to_sync';

/// EmergencyApiService
/// Handles emergency contacts and SOS API calls
class EmergencyApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
  final Dio _dio;

  EmergencyApiService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (shouldForceLogout(error)) {
            await forceLogoutFromApi();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== Emergency Contacts ====================

  /// Get all emergency contacts (with offline Hive cache fallback)
  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final response = await _dio.get('$baseUrl/emergency/contacts');

      if (response.data['success'] == true) {
        final contacts =
            List<Map<String, dynamic>>.from(response.data['contacts'] ?? []);
        return contacts;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch contacts');
      }
    } on DioException catch (e) {
      debugPrint('Failed to load contacts from backend (offline?): $e');
      // Fallback — return untouched local Hive cache
      final hive = HiveService();
      final cached = hive.getAllContacts();
      if (cached.isNotEmpty) {
        debugPrint('Returning ${cached.length} contacts from Hive cache');
        return cached.map((c) => c.toJson()).toList();
      }
      throw Exception('Network error');
    }
  }

  /// Add emergency contact (with offline queue fallback)
  Future<Map<String, dynamic>> addContact({
    required String name,
    required String phone,
    String? email,
    String relation = 'Other',
    int? priority,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/emergency/contacts',
        data: {
          'name': name,
          'phone': phone,
          if (email != null) 'email': email,
          'relation': relation,
          if (priority != null) 'priority': priority,
        },
      );

      if (response.data['success'] == true) {
        // Cache to Hive immediately
        try {
          final model =
              EmergencyContactModel.fromJson(response.data['contact']);
          await HiveService().saveContact(model);
        } catch (_) {}
        return response.data['contact'];
      } else {
        throw Exception(response.data['error'] ?? 'Failed to add contact');
      }
    } on DioException catch (_) {
      debugPrint('Offline: saving contact locally for sync later');
      // Save to pending sync queue
      final id = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      final contactData = {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'relation': relation,
        'priority': priority ?? 1,
        'isPending': true,
        'createdAt': DateTime.now().toIso8601String(),
      };
      // Save locally to Hive
      final model = EmergencyContactModel(
        id: id,
        userId: '',
        name: name,
        phoneNumber: phone,
        email: email ?? '',
        relationship: relation,
        priority: priority ?? 1,
      );
      await HiveService().saveContact(model);
      // Also save to pending queue
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_kPendingContactsKey);
      final pending = pendingJson != null
          ? List<Map<String, dynamic>>.from(jsonDecode(pendingJson))
          : <Map<String, dynamic>>[];
      pending.add(contactData);
      await prefs.setString(_kPendingContactsKey, jsonEncode(pending));
      debugPrint('Contact saved locally (pending sync): $name');
      return contactData; // return local data so UI updates immediately
    }
  }

  Future<void> syncPendingContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_kPendingContactsKey);
    if (pendingJson == null || pendingJson.isEmpty) return;

    final pending = List<Map<String, dynamic>>.from(jsonDecode(pendingJson));
    if (pending.isEmpty) return;

    final hive = HiveService();
    final remaining = <Map<String, dynamic>>[];

    for (final contact in pending) {
      try {
        final response = await _dio.post(
          '$baseUrl/emergency/contacts',
          data: {
            'name': contact['name']?.toString() ?? '',
            'phone': contact['phone']?.toString() ?? '',
            if (contact['email'] != null &&
                contact['email'].toString().isNotEmpty)
              'email': contact['email'].toString(),
            'relation': contact['relation']?.toString() ?? 'Other',
            'priority': (contact['priority'] as num?)?.toInt() ?? 1,
          },
        );
        if (response.data['success'] != true) {
          throw Exception(response.data['error'] ?? 'Failed to sync contact');
        }
        final synced =
            Map<String, dynamic>.from(response.data['contact'] ?? {});

        final pendingId = contact['id']?.toString();
        if (pendingId != null && pendingId.isNotEmpty) {
          await hive.deleteContact(pendingId);
        }
        final syncedModel = EmergencyContactModel.fromJson(synced);
        await hive.saveContact(syncedModel);
      } catch (e) {
        debugPrint('Pending contact sync failed: $e');
        remaining.add(contact);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_kPendingContactsKey);
    } else {
      await prefs.setString(_kPendingContactsKey, jsonEncode(remaining));
    }
  }

  /// Update emergency contact
  Future<Map<String, dynamic>> updateContact({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? relation,
    int? priority,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/emergency/contacts/$id',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (relation != null) 'relation': relation,
          if (priority != null) 'priority': priority,
        },
      );

      if (response.data['success'] == true) {
        return response.data['contact'];
      } else {
        throw Exception(response.data['error'] ?? 'Failed to update contact');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Delete emergency contact
  Future<void> deleteContact(String id) async {
    try {
      final response = await _dio.delete('$baseUrl/emergency/contacts/$id');

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to delete contact');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  // ==================== SOS ====================

  /// Trigger SOS alert
  Future<Map<String, dynamic>> triggerSOS({
    required double latitude,
    required double longitude,
    String? customMessage,
    List<String>? serviceTypes,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/emergency/sos',
        data: {
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
          if (customMessage != null) 'customMessage': customMessage,
          if (serviceTypes != null) 'serviceTypes': serviceTypes,
        },
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to send SOS');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Get alert history
  Future<Map<String, dynamic>> getAlertHistory({
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/emergency/alerts/history',
        queryParameters: {
          'limit': limit,
          'skip': skip,
        },
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch alerts');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Resolve alert (mark as safe)
  Future<void> resolveAlert(String alertId, {String? note}) async {
    try {
      final response = await _dio.put(
        '$baseUrl/emergency/alerts/$alertId/resolve',
        data: {
          if (note != null) 'note': note,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to resolve alert');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
