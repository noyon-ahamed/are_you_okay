import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../shared_prefs_service.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService(Dio()));

class AIService {
  final Dio _dio;
  
  // Use centralized API URL from AppConstants
  final String _baseUrl = AppConstants.apiBaseUrl; 

  AIService(this._dio);

  Future<String> sendMessage(String message) async {
    try {
      final token = await SharedPrefsService.getToken();
      
      final response = await _dio.post(
        '$_baseUrl/ai/chat',
        data: {'message': message},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['reply'];
      } else {
        throw Exception('Failed to get AI response');
      }
    } catch (e) {
      throw Exception('Error communicating with AI: $e');
    }
  }
}
