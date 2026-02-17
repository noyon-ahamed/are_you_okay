import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

/// ConfigApiService
/// Fetches app configuration from backend (including ad settings)
class ConfigApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;
  final Dio _dio = Dio();

  /// Get app configuration
  Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await _dio.get('$baseUrl/config');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch configuration');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
