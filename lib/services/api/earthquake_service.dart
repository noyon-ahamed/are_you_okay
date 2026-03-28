import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../auth/token_storage_service.dart';
import 'session_guard.dart';

final earthquakeServiceProvider =
    Provider<EarthquakeService>((ref) => EarthquakeService());

class EarthquakeService {
  static const String _cacheKeyPrefix = 'earthquake_latest_cache_v2';
  final Dio _dio;
  final String _baseUrl = AppConstants.apiBaseUrl;

  EarthquakeService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 12);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

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

  /// Get latest earthquake alerts from backend
  Future<Map<String, dynamic>> getLatestEarthquakes({
    double? lat,
    double? lng,
    String? country,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }
      if (country != null && country.isNotEmpty) {
        queryParams['country'] = country;
      }

      final response = await _dio.get(
        '$_baseUrl/earthquake/latest',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        await _saveCache(
          data,
          lat: lat,
          lng: lng,
          country: country,
        );
        return data;
      } else {
        throw Exception('Failed to fetch earthquakes');
      }
    } on DioException catch (e) {
      final cached = await getCachedEarthquakes(
        lat: lat,
        lng: lng,
        country: country,
      );
      if (cached != null) {
        return cached;
      }
      throw Exception(e.response?.data['error'] ?? 'Network error');
    } catch (e) {
      final cached = await getCachedEarthquakes(
        lat: lat,
        lng: lng,
        country: country,
      );
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCachedEarthquakes({
    double? lat,
    double? lng,
    String? country,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_cacheKeyFor(lat: lat, lng: lng, country: country));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedData = decoded['data'] as Map<String, dynamic>? ?? {};
      cachedData['_fromCache'] = true;
      cachedData['_cachedAt'] = decoded['cachedAt'];
      return cachedData;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(
    Map<String, dynamic> data, {
    double? lat,
    double? lng,
    String? country,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKeyFor(lat: lat, lng: lng, country: country),
      jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'data': data,
      }),
    );
  }

  String _cacheKeyFor({
    double? lat,
    double? lng,
    String? country,
  }) {
    final normalizedCountry = (country ?? '').trim().toLowerCase();
    final latKey = lat != null ? (lat * 10).round() / 10 : 'none';
    final lngKey = lng != null ? (lng * 10).round() / 10 : 'none';
    return '$_cacheKeyPrefix:$normalizedCountry:$latKey:$lngKey';
  }

  /// Trigger manual earthquake data fetch
  Future<void> fetchNow() async {
    try {
      await _dio.post('$_baseUrl/earthquake/fetch-now');
    } catch (e) {
      throw Exception('Failed to trigger earthquake fetch: $e');
    }
  }
}
