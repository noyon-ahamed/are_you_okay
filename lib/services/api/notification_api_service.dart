import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../auth/token_storage_service.dart';
import 'session_guard.dart';

/// NotificationApiService
/// Handles notification API calls with JWT
class NotificationApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
  final Dio _dio;

  NotificationApiService() : _dio = Dio() {
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

  /// Get all notifications
  Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int skip = 0,
    String? latestCreatedAt,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit,
        'skip': skip,
      };
      if (latestCreatedAt != null && latestCreatedAt.isNotEmpty) {
        queryParameters['latestCreatedAt'] = latestCreatedAt;
      }

      final response = await _dio.get(
        '$baseUrl/notification',
        queryParameters: queryParameters,
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(
            response.data['error'] ?? 'Failed to fetch notifications');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.put('$baseUrl/notification/$notificationId/read');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _dio.put('$baseUrl/notification/read-all');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('$baseUrl/notification/$notificationId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      await _dio.delete('$baseUrl/notification');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
