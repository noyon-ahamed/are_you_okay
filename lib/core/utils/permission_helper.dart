import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Permission Helper
/// Handles all app permissions
class PermissionHelper {
  /// Check and request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.location.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Location permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check and request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Notification permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check and request contacts permission
  static Future<bool> requestContactsPermission() async {
    try {
      final status = await Permission.contacts.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.contacts.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Contacts permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting contacts permission: $e');
      return false;
    }
  }

  /// Check and request phone permission
  static Future<bool> requestPhonePermission() async {
    try {
      final status = await Permission.phone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.phone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Phone permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting phone permission: $e');
      return false;
    }
  }

  /// Check and request sms permission
  static Future<bool> requestSMSPermission() async {
    try {
      final status = await Permission.sms.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.sms.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('SMS permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
      return false;
    }
  }

  /// Check and request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Camera permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Check and request storage permission
  static Future<bool> requestStoragePermission() async {
    try {
      final status = await Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Storage permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Request all essential permissions
  static Future<Map<String, bool>> requestAllEssentialPermissions() async {
    return {
      'location': await requestLocationPermission(),
      'notification': await requestNotificationPermission(),
      'contacts': await requestContactsPermission(),
    };
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if contacts permission is granted
  static Future<bool> isContactsPermissionGranted() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Get permission status
  static Future<PermissionStatus> getPermissionStatus(
    Permission permission,
  ) async {
    return await permission.status;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(
    Permission permission,
  ) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Get Bengali permission explanation
  static String getPermissionExplanationBangla(String permissionType) {
    switch (permissionType) {
      case 'location':
        return 'আপনার জরুরি অবস্থান ট্র্যাক করতে লোকেশন অনুমতি প্রয়োজন।';
      case 'notification':
        return 'আপনাকে রিমাইন্ডার এবং জরুরি সতর্কতা পাঠাতে নোটিফিকেশন অনুমতি প্রয়োজন।';
      case 'contacts':
        return 'জরুরি যোগাযোগ যোগ করতে কন্টাক্ট অনুমতি প্রয়োজন।';
      case 'phone':
        return 'জরুরি কল করতে ফোন অনুমতি প্রয়োজন।';
      case 'sms':
        return 'জরুরি এসএমএস পাঠাতে এসএমএস অনুমতি প্রয়োজন।';
      case 'camera':
        return 'প্রোফাইল ছবি আপডেট করতে ক্যামেরা অনুমতি প্রয়োজন।';
      case 'storage':
        return 'ফাইল সংরক্ষণ করতে স্টোরেজ অনুমতি প্রয়োজন।';
      default:
        return 'এই বৈশিষ্ট্য ব্যবহার করতে অনুমতি প্রয়োজন।';
    }
  }
}
