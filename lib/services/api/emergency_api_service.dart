import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../auth/token_storage_service.dart';

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
      ),
    );
  }

  // ==================== Emergency Contacts ====================

  /// Get all emergency contacts
  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final response = await _dio.get('$baseUrl/emergency/contacts');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['contacts'] ?? []);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch contacts');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Add emergency contact
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
        return response.data['contact'];
      } else {
        throw Exception(response.data['error'] ?? 'Failed to add contact');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
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
