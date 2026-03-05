import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../auth/token_storage_service.dart';
import '../shared_prefs_service.dart';
import '../../routes/app_router.dart';
import 'package:go_router/go_router.dart';

const String _kMoodHistoryCache = 'mood_history_cache';
const String _kMoodStatsCache = 'mood_stats_cache';

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
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await SharedPrefsService().logout();
            await TokenStorageService.clearAll();
            if (rootNavigatorKey.currentContext != null) {
              rootNavigatorKey.currentContext!.go(Routes.login);
            }
          }
          return handler.next(error);
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
      final errorMsg =
          e.response?.data?['error']?.toString() ?? 'Network error';
      throw Exception('$statusCode: $errorMsg');
    }
  }

  /// Get mood history (with persistent offline cache)
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
        // Persist to local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kMoodHistoryCache, jsonEncode(response.data));
        debugPrint('Mood history cached to disk');
        return response.data;
      } else {
        throw Exception(
            response.data['error'] ?? 'Failed to fetch mood history');
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch history from backend: $e');
      // Fall back to persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kMoodHistoryCache);
      if (cached != null) {
        debugPrint('Returning mood history from persistent cache');
        return jsonDecode(cached) as Map<String, dynamic>;
      }
      throw Exception('Network error');
    }
  }

  /// Get mood stats (with persistent offline cache)
  Future<Map<String, dynamic>> getStats({int days = 30}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/mood/stats',
        queryParameters: {'days': days},
      );

      if (response.data['success'] == true) {
        // Persist to local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kMoodStatsCache, jsonEncode(response.data));
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch mood stats');
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch mood stats from backend: $e');
      // Fall back to persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kMoodStatsCache);
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
      throw Exception('Network error');
    }
  }
}
