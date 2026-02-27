import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';

/// Local Notification Service
/// Handles local notifications including scheduled reminders
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Fixed notification IDs for check-in reminders
  static const int _reminder6hId = 100;
  static const int _reminder2hId = 101;
  static const int _reminder30mId = 102;

  /// Initialize local notifications
  Future<void> initialize({
    required Function(String?) onNotificationTap,
  }) async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

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
        await _requestAndroidPermissions();
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

  /// Request Android notification permissions (Android 13+)
  Future<void> _requestAndroidPermissions() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
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

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(emergencyChannel);
    await androidImpl?.createNotificationChannel(reminderChannel);
    await androidImpl?.createNotificationChannel(infoChannel);
  }

  /// Show notification immediately
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

  /// Schedule a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = 'checkin_reminders',
  }) async {
    try {
      // Don't schedule in the past
      if (scheduledDate.isBefore(DateTime.now())) {
        debugPrint('Skipping notification $id — scheduled time is in the past');
        return;
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'emergency_alerts'
            ? 'জরুরি সতর্কতা'
            : 'চেক-ইন রিমাইন্ডার',
        channelDescription: 'চেক-ইন রিমাইন্ডার নোটিফিকেশন',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Notification $id scheduled for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Schedule 3 escalating check-in reminders
  /// Called after each successful check-in with the next check-in deadline
  Future<void> scheduleCheckinReminders(DateTime nextCheckInDeadline) async {
    // Cancel any existing reminders first
    await cancelCheckinReminders();

    // Reminder 1: 6 hours before deadline
    final reminder6h = nextCheckInDeadline.subtract(const Duration(hours: 6));
    await scheduleNotification(
      id: _reminder6hId,
      title: 'চেক-ইন রিমাইন্ডার 🔔',
      body: 'আপনার চেক-ইন করার সময় ৬ ঘণ্টা বাকি আছে।',
      scheduledDate: reminder6h,
      payload: 'checkin_reminder_6h',
    );

    // Reminder 2: 2 hours before deadline
    final reminder2h = nextCheckInDeadline.subtract(const Duration(hours: 2));
    await scheduleNotification(
      id: _reminder2hId,
      title: 'চেক-ইন প্রয়োজন ⚠️',
      body: 'আপনার চেক-ইন করার সময় মাত্র ২ ঘণ্টা বাকি! অনুগ্রহ করে চেক-ইন করুন।',
      scheduledDate: reminder2h,
      payload: 'checkin_reminder_2h',
    );

    // Reminder 3: 30 minutes before deadline (critical)
    final reminder30m = nextCheckInDeadline.subtract(const Duration(minutes: 30));
    await scheduleNotification(
      id: _reminder30mId,
      title: '🚨 জরুরি চেক-ইন করুন!',
      body: 'আপনার চেক-ইনের সময় প্রায় শেষ! এখনই চেক-ইন করুন, নাহলে আপনার জরুরি যোগাযোগে সতর্কতা পাঠানো হবে।',
      scheduledDate: reminder30m,
      payload: 'checkin_reminder_critical',
      channelId: 'emergency_alerts',
    );

    debugPrint('Scheduled 3 check-in reminders for deadline: $nextCheckInDeadline');
  }

  /// Cancel all check-in reminders
  Future<void> cancelCheckinReminders() async {
    await _notifications.cancel(_reminder6hId);
    await _notifications.cancel(_reminder2hId);
    await _notifications.cancel(_reminder30mId);
    debugPrint('Cancelled all check-in reminders');
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

  /// Show check-in reminder (immediate)
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
