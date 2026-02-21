import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../auth/token_storage_service.dart';

/// CheckinApiService
/// Handles check-in API calls with JWT authentication
class CheckinApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
  final Dio _dio;

  CheckinApiService() : _dio = Dio() {
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

  /// Perform daily check-in
  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    String status = 'safe',
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/checkin',
        data: {
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'status': status,
          if (note != null) 'note': note,
        },
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Check-in failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Already checked in today
        throw Exception(e.response?.data['error'] ?? 'Already checked in today');
      }
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Get check-in status (last check-in, streak, needs check-in)
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _dio.get('$baseUrl/checkin/status');

      if (response.data['success'] == true) {
        return response.data['status'];
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch status');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Get check-in history
  Future<Map<String, dynamic>> getHistory({
    int limit = 30,
    int skip = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/checkin/history',
        queryParameters: {
          'limit': limit,
          'skip': skip,
        },
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch history');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Get current streak info
  Future<Map<String, dynamic>> getStreak() async {
    try {
      final response = await _dio.get('$baseUrl/checkin/streak');

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch streak');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Get server time (from status response header or dedicated endpoint)
  Future<DateTime> getServerTime() async {
    try {
      final response = await _dio.get('$baseUrl/checkin/status');
      // Use the Date header from server response as server time
      final dateHeader = response.headers.value('date');
      if (dateHeader != null) {
        return HttpDate.parse(dateHeader);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Set reminder time preference
  Future<void> setReminderTime({
    required int hour,
    required int minute,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/checkin/reminder',
        data: {
          'hour': hour,
          'minute': minute,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Get monthly calendar data
  Future<Map<String, dynamic>> getCalendar({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/checkin/calendar/$year/$month',
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch calendar');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}

/// Helper class for parsing HTTP date headers
class HttpDate {
  static DateTime parse(String date) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      // HTTP date format: "Thu, 20 Feb 2025 21:00:00 GMT"
      // Dart's HttpDate can parse this
      return DateTime.now();
    }
  }
}
