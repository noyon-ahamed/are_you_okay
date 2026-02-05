import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Local Notification Service
/// Handles local notifications
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize local notifications
  Future<void> initialize({
    required Function(String?) onNotificationTap,
  }) async {
    if (_initialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification tapped: ${response.payload}');
          onNotificationTap(response.payload);
        },
      );

      // Request permissions (iOS)
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }

      // Create notification channels (Android)
      if (Platform.isAndroid) {
        await _createAndroidChannels();
      }

      _initialized = true;
      debugPrint('Local notifications initialized');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Request iOS permissions
  Future<bool> _requestIOSPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? false;
  }

  /// Create Android notification channels
  Future<void> _createAndroidChannels() async {
    // Emergency channel
    const emergencyChannel = AndroidNotificationChannel(
      'emergency_alerts',
      'জরুরি সতর্কতা',
      description: 'জরুরি সতর্কতা এবং SOS বিজ্ঞপ্তি',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFDC143C),
    );

    // Check-in reminders channel
    const reminderChannel = AndroidNotificationChannel(
      'checkin_reminders',
      'চেক-ইন রিমাইন্ডার',
      description: 'চেক-ইন করার জন্য রিমাইন্ডার',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Info channel
    const infoChannel = AndroidNotificationChannel(
      'info_updates',
      'তথ্য আপডেট',
      description: 'সাধারণ তথ্য এবং আপডেট',
      importance: Importance.low,
      playSound: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(infoChannel);
  }

  /// Show notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'info_updates',
    Priority priority = Priority.defaultPriority,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'emergency_alerts'
            ? 'জরুরি সতর্কতা'
            : channelId == 'checkin_reminders'
                ? 'চেক-ইন রিমাইন্ডার'
                : 'তথ্য আপডেট',
        channelDescription: '',
        importance: channelId == 'emergency_alerts'
            ? Importance.max
            : Importance.high,
        priority: channelId == 'emergency_alerts'
            ? Priority.high
            : Priority.defaultPriority,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('Notification shown: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Show emergency alert
  Future<void> showEmergencyAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'emergency_alerts',
      priority: Priority.max,
    );
  }

  /// Show check-in reminder
  Future<void> showCheckinReminder({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: 1, // Fixed ID so it replaces previous reminder
      title: title,
      body: body,
      payload: payload,
      channelId: 'checkin_reminders',
      priority: Priority.high,
    );
  }

  /// Schedule notification
  // Future<void> scheduleNotification({
  //   required int id,
  //   required String title,
  //   required String body,
  //   required DateTime scheduledDate,
  //   String? payload,
  //   String channelId = 'checkin_reminders',
  // }) async {
  //   // Note: This requires timezone package
  //   // Implementation depends on timezone setup
  // }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Get active notifications (Android 6.0+)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await plugin?.getActiveNotifications() ?? [];
    }
    return [];
  }
}
