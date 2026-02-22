import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../auth/token_storage_service.dart';

/// MoodApiService
/// Handles mood tracking API calls
class MoodApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
  final Dio _dio;

  MoodApiService() : _dio = Dio() {
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

  /// Save mood entry
  Future<Map<String, dynamic>> saveMood({
    required String mood,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/mood',
        data: {
          'mood': mood,
          if (note != null) 'note': note,
        },
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to save mood');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final errorMsg = e.response?.data?['error']?.toString() ?? 'Network error';
      throw Exception('$statusCode: $errorMsg');
    }
  }

  /// Get mood history
  Future<Map<String, dynamic>> getHistory({
    int limit = 30,
    int skip = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mood/history',
        queryParameters: {
          'limit': limit,
          'skip': skip,
        },
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch mood history');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Get mood stats
  Future<Map<String, dynamic>> getStats({int days = 30}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mood/stats',
        queryParameters: {'days': days},
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch mood stats');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
