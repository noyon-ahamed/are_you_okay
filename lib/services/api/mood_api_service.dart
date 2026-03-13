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
const String _kMoodHistoryMeta = 'mood_history_cache_meta';

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
        '$baseUrl/mood/history',
        queryParameters: queryParameters,
      );

      if (response.data['success'] == true) {
        final mergedResponse = await _mergeAndPersistHistoryCache(
          response.data as Map<String, dynamic>,
        );
        debugPrint('Mood history cached to disk');
        return mergedResponse;
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

  Future<Map<String, dynamic>?> getCachedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kMoodHistoryCache);
    if (cached == null || cached.isEmpty) return null;

    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getLatestHistoryCreatedAt() async {
    final cached = await getCachedHistory();
    final moods = _extractMoodList(cached);
    if (moods.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMoodHistoryMeta);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['latestCreatedAt']?.toString();
    } catch (_) {
      return null;
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

  Future<Map<String, dynamic>?> getCachedStats() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kMoodStatsCache);
    if (cached == null || cached.isEmpty) return null;

    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _mergeAndPersistHistoryCache(
    Map<String, dynamic> responseData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getCachedHistory();
    final existingMoods = _extractMoodList(existing);
    final incomingMoods = _extractMoodList(responseData);

    final mergedMoods = _mergeMoodLists(incomingMoods, existingMoods);
    final mergedResponse = <String, dynamic>{
      ...responseData,
      'moods': mergedMoods,
    };

    await prefs.setString(_kMoodHistoryCache, jsonEncode(mergedResponse));
    final latestCreatedAt =
        responseData['sync']?['latestCreatedAt']?.toString() ??
            _findLatestMoodTimestamp(mergedMoods);
    if (latestCreatedAt != null && latestCreatedAt.isNotEmpty) {
      await prefs.setString(
        _kMoodHistoryMeta,
        jsonEncode({'latestCreatedAt': latestCreatedAt}),
      );
    }

    return mergedResponse;
  }

  List<Map<String, dynamic>> _extractMoodList(Map<String, dynamic>? data) {
    final moods = data?['moods'];
    if (moods is! List) return <Map<String, dynamic>>[];
    return moods
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _mergeMoodLists(
    List<Map<String, dynamic>> incoming,
    List<Map<String, dynamic>> existing,
  ) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final item in [...incoming, ...existing]) {
      final normalized = Map<String, dynamic>.from(item);
      final id = normalized['_id']?.toString() ?? normalized['id']?.toString();
      final timestamp = normalized['timestamp']?.toString() ?? '';
      final key = id != null && id.isNotEmpty
          ? 'id:$id'
          : 'ts:$timestamp|${normalized['mood']}|${normalized['note']}';
      if (seen.add(key)) {
        merged.add(normalized);
      }
    }

    merged.sort((a, b) {
      final aTs = DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTs = DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTs.compareTo(aTs);
    });
    return merged;
  }

  String? _findLatestMoodTimestamp(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) return null;
    return moods
        .map((item) => item['timestamp']?.toString())
        .whereType<String>()
        .fold<String?>(null, (latest, current) {
      if (latest == null) return current;
      final latestDate = DateTime.tryParse(latest);
      final currentDate = DateTime.tryParse(current);
      if (currentDate == null) return latest;
      if (latestDate == null || currentDate.isAfter(latestDate)) {
        return current;
      }
      return latest;
    });
  }
}
