import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../shared_prefs_service.dart';
import '../auth/token_storage_service.dart';

/// AuthApiService
/// Handles authentication API calls with JWT
class AuthApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
  final Dio _dio = Dio();

  AuthApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 20);

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
          return handler.next(error);
        },
      ),
    );
  }

  /// Send FCM token to backend
  Future<void> sendFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      debugPrint('FCM Token: $fcmToken');
      await _dio.post(
        '$baseUrl/auth/fcm-token',
        data: {'fcmToken': fcmToken},
      );
      debugPrint('FCM token sent to backend');
    } catch (e) {
      debugPrint('FCM token send failed: $e');
    }
  }

  /// Remove FCM token from backend on logout
  Future<void> removeFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await _dio.delete(
        '$baseUrl/auth/fcm-token',
        data: {'fcmToken': fcmToken},
      );
      debugPrint('FCM token removed from backend');
    } catch (e) {
      // Non-critical — logout should proceed even if this fails
      debugPrint('FCM token removal failed (non-critical): $e');
    }
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

        await TokenStorageService.saveToken(token);
        await TokenStorageService.saveUserId(userId);
        await SharedPrefsService().setUserToken(token);
        await SharedPrefsService().setUserId(userId);

        unawaited(sendFcmToken());

        return response.data['data'];
      } else {
        throw Exception(response.data['error'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.error.toString().contains('SocketException')) {
        throw Exception('No Internet Connection');
      }
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Logout user
  Future<void> logout() async {
    // ✅ আগে FCM token server থেকে remove করো
    // এটা fail হলেও logout চলবে
    await removeFcmToken();
    await SharedPrefsService().logout();
    await TokenStorageService.clearAll();
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
    String? address,
    String? bloodGroup,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/auth/profile',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (profilePicture != null) 'profilePicture': profilePicture,
          if (address != null) 'address': address,
          if (bloodGroup != null) 'bloodGroup': bloodGroup,
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

  Future<void> updateNotificationPreferences({
    bool? notificationEnabled,
    bool? smsAlerts,
    bool? wellnessReminders,
    bool? emergencyAlerts,
    List<String>? reminderTimes,
    String? timezone,
    String? language,
    bool? earthquakeAlerts,
    String? earthquakeCountry,
  }) async {
    try {
      await _dio.put(
        '$baseUrl/auth/notification-preferences',
        data: {
          if (notificationEnabled != null)
            'notificationEnabled': notificationEnabled,
          if (smsAlerts != null) 'smsAlerts': smsAlerts,
          if (wellnessReminders != null) 'wellnessReminders': wellnessReminders,
          if (emergencyAlerts != null) 'emergencyAlerts': emergencyAlerts,
          if (reminderTimes != null) 'reminderTimes': reminderTimes,
          if (timezone != null) 'timezone': timezone,
          if (language != null) 'language': language,
          if (earthquakeAlerts != null) 'earthquakeAlerts': earthquakeAlerts,
          if (earthquakeCountry != null) 'earthquakeCountry': earthquakeCountry,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/auth/update-location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
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

  /// Verify OTP
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.data['success'] == true) {
        return response.data['data']['resetToken'] as String;
      } else {
        throw Exception(response.data['error'] ?? 'OTP verification failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  /// Reset password
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

  /// Verify email
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

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final response = await _dio.delete('$baseUrl/auth/account');

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to delete account');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
