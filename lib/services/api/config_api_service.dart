import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

/// ConfigApiService
/// Fetches app configuration from backend (including ad settings)
class ConfigApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
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

  Future<int> getMaxEmergencyContacts() async {
    try {
      final config = await getConfig();
      final settings = config['settings'] as Map<String, dynamic>?;
      final maxContacts = settings?['maxEmergencyContacts'];
      if (maxContacts is num && maxContacts > 0) {
        return maxContacts.toInt();
      }
    } catch (_) {}

    return AppConstants.maxEmergencyContacts;
  }
}
