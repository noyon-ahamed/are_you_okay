import 'package:dio/dio.dart';
import '../shared_prefs_service.dart';

/// AuthApiService
/// Handles authentication API calls with JWT
class AuthApiService {
  static const String baseUrl = 'http://10.10.5.53:3000/api'; // Use Computer's Local IP for Physical Device
  final Dio _dio = Dio();

  AuthApiService() {
    // Add token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SharedPrefsService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - token expired
          if (error.response?.statusCode == 401) {
            await SharedPrefsService().clearAll();
            // Optionally navigate to login screen here
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final userId = response.data['data']['user']['id'];
        
        await SharedPrefsService().setUserToken(token);
        await SharedPrefsService().setUserId(userId);
        
        return response.data['data'];
      } else {
        throw Exception(response.data['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final userId = response.data['data']['user']['id'];
        
        await SharedPrefsService().setUserToken(token);
        await SharedPrefsService().setUserId(userId);
        
        return response.data['data'];
      } else {
        throw Exception(response.data['error'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Logout user
  Future<void> logout() async {
    await SharedPrefsService().clearAll();
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('$baseUrl/auth/profile');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch profile');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/auth/profile',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (profilePicture != null) 'profilePicture': profilePicture,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['error'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Request password reset
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/forgot-password',
        data: {'email': email},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to send reset email');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/reset-password',
        data: {
          'token': token,
          'password': newPassword,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to reset password');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Verify email with token
  Future<void> verifyEmail(String token) async {
    try {
      final response = await _dio.get('$baseUrl/auth/verify-email/$token');

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to verify email');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
