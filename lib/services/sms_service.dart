import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// SMS Service
/// Handles SMS sending via SSL Wireless (Bangladesh)
class SMSService {
  final Dio _dio = Dio();
  
  // SSL Wireless API Configuration
  // TODO: Replace with actual credentials from SSL Wireless
  static const String _baseUrl = 'https://smsplus.sslwireless.com/api/v3';
  static const String _apiToken = 'YOUR_SSL_API_TOKEN'; // Replace this
  static const String _sid = 'YOUR_SID'; // Replace this
  
  /// Send SMS
  Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Ensure phone number is in correct format (8801XXXXXXXXX)
      final formattedPhone = _formatBangladeshPhone(phoneNumber);
      
      debugPrint('Sending SMS to: $formattedPhone');
      
      final response = await _dio.post(
        '$_baseUrl/send-sms',
        data: {
          'api_token': _apiToken,
          'sid': _sid,
          'msisdn': formattedPhone,
          'sms': message,
          'csms_id': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (response.statusCode == 200) {
        debugPrint('SMS sent successfully');
        return true;
      } else {
        debugPrint('SMS send failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      // Try backup provider if available
      return await _sendViaBackupProvider(phoneNumber, message);
    }
  }

  /// Send emergency alert SMS
  Future<bool> sendEmergencyAlert({
    required String phoneNumber,
    required String userName,
    required String? location,
    bool isSOS = false,
  }) async {
    final message = isSOS
        ? _buildSOSMessage(userName: userName, location: location)
        : _buildMissedCheckinMessage(userName: userName, location: location);

    return await sendSMS(phoneNumber: phoneNumber, message: message);
  }

  /// Send bulk SMS to multiple contacts
  Future<Map<String, bool>> sendBulkSMS({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final results = <String, bool>{};

    for (final phone in phoneNumbers) {
      final success = await sendSMS(phoneNumber: phone, message: message);
      results[phone] = success;
      
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }

  /// Send bulk emergency alerts
  Future<Map<String, bool>> sendBulkEmergencyAlerts({
    required List<String> phoneNumbers,
    required String userName,
    required String userPhone,
    required String? location,
    bool isSOS = false,
  }) async {
    final message = isSOS
        ? _buildSOSMessage(
            userName: userName,
            userPhone: userPhone,
            location: location,
          )
        : _buildMissedCheckinMessage(
            userName: userName,
            userPhone: userPhone,
            location: location,
          );

    return await sendBulkSMS(phoneNumbers: phoneNumbers, message: message);
  }

  /// Build SOS message
  String _buildSOSMessage({
    required String userName,
    String? userPhone,
    String? location,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('জরুরি সাহায্য প্রয়োজন!');
    buffer.writeln('$userName SOS সিগন্যাল পাঠিয়েছেন।');
    
    if (location != null && location.isNotEmpty) {
      buffer.writeln('অবস্থান: $location');
    }
    
    if (userPhone != null && userPhone.isNotEmpty) {
      buffer.writeln('ফোন: $userPhone');
    }
    
    buffer.writeln('অবিলম্বে যোগাযোগ করুন!');
    buffer.write('- ভালো আছেন কি? অ্যাপ');

    return buffer.toString();
  }

  /// Build missed check-in message
  String _buildMissedCheckinMessage({
    required String userName,
    String? userPhone,
    String? location,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('জরুরি:');
    buffer.writeln('$userName দীর্ঘ সময় ধরে চেক-ইন করেননি।');
    
    if (location != null && location.isNotEmpty) {
      buffer.writeln('শেষ অবস্থান: $location');
    }
    
    if (userPhone != null && userPhone.isNotEmpty) {
      buffer.writeln('যোগাযোগ: $userPhone');
    }
    
    buffer.write('- ভালো আছেন কি? অ্যাপ');

    return buffer.toString();
  }

  /// Format Bangladesh phone number
  String _formatBangladeshPhone(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Handle different formats
    if (cleaned.startsWith('880')) {
      // Already in correct format
      return cleaned;
    } else if (cleaned.startsWith('0')) {
      // Remove leading 0 and add 880
      return '880${cleaned.substring(1)}';
    } else if (cleaned.startsWith('1')) {
      // Add 880
      return '880$cleaned';
    }

    return cleaned;
  }

  /// Send via backup provider (Twilio, BulkSMS, etc.)
  Future<bool> _sendViaBackupProvider(String phoneNumber, String message) async {
    try {
      // TODO: Implement backup SMS provider
      debugPrint('Attempting backup SMS provider...');
      
      // For now, just return false
      // You can implement Twilio or other backup here
      return false;
    } catch (e) {
      debugPrint('Backup SMS provider also failed: $e');
      return false;
    }
  }

  /// Validate Bangladesh phone number
  bool isValidBangladeshPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it matches Bangladesh phone format
    // 11 digits starting with 01 or 13 digits starting with 880
    if (cleaned.length == 11 && cleaned.startsWith('01')) {
      return true;
    }
    if (cleaned.length == 13 && cleaned.startsWith('880')) {
      return true;
    }
    
    return false;
  }

  /// Get SMS credit balance (SSL Wireless specific)
  Future<double?> getSMSBalance() async {
    try {
      final response = await _dio.post(
        '$_baseUrl/get-balance',
        data: {
          'api_token': _apiToken,
          'sid': _sid,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return double.tryParse(response.data['balance']?.toString() ?? '0');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting SMS balance: $e');
      return null;
    }
  }
}
