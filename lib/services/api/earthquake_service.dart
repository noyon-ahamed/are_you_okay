import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared_prefs_service.dart';

final earthquakeServiceProvider = Provider<EarthquakeService>((ref) => EarthquakeService(Dio()));

class EarthquakeService {
  final Dio _dio;
  
  // TODO: Update with your actual backend URL
  final String _baseUrl = 'http://10.0.2.2:3000/api'; 

  EarthquakeService(this._dio);

  Future<List<dynamic>> getRecentEarthquakes() async {
    try {
      final token = await SharedPrefsService.getToken();
      
      final response = await _dio.get(
        '$_baseUrl/earthquake/recent',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['earthquakes'] ?? [];
      } else {
        throw Exception('Failed to fetch earthquakes');
      }
    } catch (e) {
      throw Exception('Error fetching earthquakes: $e');
    }
  }
}
