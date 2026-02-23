import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../auth/token_storage_service.dart';

final earthquakeServiceProvider = Provider<EarthquakeService>((ref) => EarthquakeService());

class EarthquakeService {
  final Dio _dio;
  final String _baseUrl = AppConstants.apiBaseUrl;

  EarthquakeService() : _dio = Dio() {
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

  /// Get latest earthquake alerts from backend
  Future<Map<String, dynamic>> getLatestEarthquakes({double? lat, double? lng}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }

      final response = await _dio.get(
        '$_baseUrl/earthquake/latest',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>? ?? {};
      } else {
        throw Exception('Failed to fetch earthquakes');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
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
