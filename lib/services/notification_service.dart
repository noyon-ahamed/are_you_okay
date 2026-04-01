import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';
import '../core/localization/app_strings.dart';
import 'earthquake_alarm_service.dart';

const String seismicNotificationCategoryId = 'earthquake_siren_category';
const String stopSirenActionId = 'stop_earthquake_siren';

bool _payloadContainsEarthquake(String? payload) {
  if (payload == null || payload.isEmpty) return false;

  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      final type = decoded['type']?.toString();
      if (type == 'earthquake') {
        return true;
      }
    }
  } catch (_) {
    return payload.contains('earthquake');
  }

  return payload.contains('earthquake');
}

Future<void> _stopSirenFromNotification(NotificationResponse response) async {
  await EarthquakeAlarmService().stop();

  final id = response.id;
  if (id != null) {
    try {
      await FlutterLocalNotificationsPlugin().cancel(id);
    } catch (error) {
      debugPrint('Failed to cancel seismic notification: $error');
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  unawaited(() async {
    if (notificationResponse.actionId == stopSirenActionId ||
        _payloadContainsEarthquake(notificationResponse.payload)) {
      await _stopSirenFromNotification(notificationResponse);
    }
  }());
}

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

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('language') ?? 'en';
      final isBn = lang == 'bn';

      // Android initialization settings — use monochrome drawable for notification tray icon
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      // iOS initialization settings
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            seismicNotificationCategoryId,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                stopSirenActionId,
                isBn ? 'সাইরেন বন্ধ' : 'Stop Siren',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.destructive,
                },
              ),
            ],
          ),
        ],
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) async {
          debugPrint('Notification tapped: ${response.payload}');

          if (response.actionId == stopSirenActionId) {
            await _stopSirenFromNotification(response);
            return;
          }

          if (_payloadContainsEarthquake(response.payload)) {
            await EarthquakeAlarmService().stop();
          }

          onNotificationTap(response.payload);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  /// Create Android notification channels
  Future<void> _createAndroidChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'en';
    final s = AppStrings(lang: lang);

    // Emergency channel
    final emergencyChannel = AndroidNotificationChannel(
      'emergency_alerts',
      s.channelEmergencyTitle,
      description: s.channelEmergencyDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFDC143C),
      showBadge: true,
    );

    // Check-in reminders channel
    final reminderChannel = AndroidNotificationChannel(
      'checkin_reminders',
      s.channelCheckinTitle,
      description: s.channelCheckinDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Seismic Alerts channel (for close earthquakes)
    final seismicChannel = AndroidNotificationChannel(
      'seismic_alerts',
      s.channelEarthquakeTitle,
      description: s.channelEarthquakeDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1200, 600, 1200]),
      enableLights: true,
      ledColor: const Color(0xFFDC143C),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    // Info channel
    final infoChannel = AndroidNotificationChannel(
      'info_updates',
      s.channelGeneralTitle,
      description: s.channelGeneralDesc,
      importance: Importance.low,
      playSound: false,
    );

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(emergencyChannel);
    await androidImpl?.createNotificationChannel(reminderChannel);
    await androidImpl?.createNotificationChannel(seismicChannel);
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
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('language') ?? 'en';
      final isBn = lang == 'bn';
      final isAlarmChannel =
          channelId == 'emergency_alerts' || channelId == 'seismic_alerts';
      final isSeismicChannel = channelId == 'seismic_alerts';
      final androidDetails = AndroidNotificationDetails(
        channelId,
        isSeismicChannel
            ? 'ভূমিকম্প সাইরেন'
            : channelId == 'emergency_alerts'
                ? 'জরুরি সতর্কতা'
                : channelId == 'checkin_reminders'
                    ? 'চেক-ইন রিমাইন্ডার'
                    : 'তথ্য আপডেট',
        channelDescription: '',
        importance: isAlarmChannel ? Importance.max : Importance.high,
        priority: isAlarmChannel ? Priority.max : Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern:
            isSeismicChannel ? Int64List.fromList([0, 1200, 600, 1200]) : null,
        fullScreenIntent: isAlarmChannel,
        autoCancel: !isSeismicChannel,
        ongoing: isSeismicChannel,
        icon: 'ic_notification',
        visibility: NotificationVisibility.public,
        showWhen: true,
        category: isAlarmChannel
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        audioAttributesUsage: isSeismicChannel
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        actions: isSeismicChannel
            ? <AndroidNotificationAction>[
                AndroidNotificationAction(
                  stopSirenActionId,
                  isBn ? 'সাইরেন বন্ধ' : 'Stop Siren',
                  showsUserInterface: false,
                ),
              ]
            : null,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        interruptionLevel: isAlarmChannel
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
        categoryIdentifier:
            isSeismicChannel ? seismicNotificationCategoryId : null,
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

  /// Schedule a notification at a specific time (one-shot)
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
        channelId == 'emergency_alerts' ? 'জরুরি সতর্কতা' : 'চেক-ইন রিমাইন্ডার',
        channelDescription: 'চেক-ইন রিমাইন্ডার নোটিফিকেশন',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'ic_notification',
        color: const Color(0xFFDC143C),
        visibility: NotificationVisibility.public,
        showWhen: true,
        category: AndroidNotificationCategory.reminder,
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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Notification $id scheduled for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Schedule a daily repeating notification at a fixed time (HH:MM).
  /// Uses DateTimeComponents.time so it fires every day at that time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    String channelId = 'checkin_reminders',
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'চেক-ইন রিমাইন্ডার',
        channelDescription: 'দৈনিক চেক-ইন রিমাইন্ডার',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'ic_notification',
        color: const Color(0xFFDC143C),
        visibility: NotificationVisibility.public,
        showWhen: true,
        category: AndroidNotificationCategory.reminder,
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
        scheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // Repeat daily at the same time
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
          'Daily notification $id scheduled at $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('Error scheduling daily notification: $e');
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
      body:
          'আপনার চেক-ইন করার সময় মাত্র ২ ঘণ্টা বাকি! অনুগ্রহ করে চেক-ইন করুন।',
      scheduledDate: reminder2h,
      payload: 'checkin_reminder_2h',
    );

    // Reminder 3: 30 minutes before deadline (critical)
    final reminder30m =
        nextCheckInDeadline.subtract(const Duration(minutes: 30));
    await scheduleNotification(
      id: _reminder30mId,
      title: '🚨 জরুরি চেক-ইন করুন!',
      body:
          'আপনার চেক-ইনের সময় প্রায় শেষ! এখনই চেক-ইন করুন, নাহলে আপনার জরুরি যোগাযোগে সতর্কতা পাঠানো হবে।',
      scheduledDate: reminder30m,
      payload: 'checkin_reminder_critical',
      channelId: 'emergency_alerts',
    );

    debugPrint(
        'Scheduled 3 check-in reminders for deadline: $nextCheckInDeadline');
  }

  /// Cancel all check-in reminders
  Future<void> cancelCheckinReminders() async {
    await _notifications.cancel(_reminder6hId);
    await _notifications.cancel(_reminder2hId);
    await _notifications.cancel(_reminder30mId);
    debugPrint('Cancelled all check-in reminders');
  }

  // Fixed IDs for the 3 daily reminders
  static const int _dailyMorningId = 201;
  static const int _dailyNoonId = 202;
  static const int _dailyNightId = 203;

  /// Cancel the 3 fixed daily reminders
  Future<void> cancelDailyReminders() async {
    await _notifications.cancel(_dailyMorningId);
    await _notifications.cancel(_dailyNoonId);
    await _notifications.cancel(_dailyNightId);
    debugPrint('Cancelled 3 daily reminders');
  }

  /// Show emergency alert
  Future<void> showEmergencyAlert({
    int? id,
    required String title,
    required String body,
    String? payload,
    bool isSeismicClose = false,
  }) async {
    await showNotification(
      id: id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: isSeismicClose ? 'seismic_alerts' : 'emergency_alerts',
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

  Future<void> cancelMatchingNotification({
    int? id,
    String? title,
    String? body,
    String? payload,
  }) async {
    if (id != null) {
      await cancelNotification(id);
      return;
    }

    final activeNotifications = await getActiveNotifications();
    for (final notification in activeNotifications) {
      final payloadMatches = payload != null &&
          payload.isNotEmpty &&
          notification.payload == payload;
      final contentMatches = title != null &&
          title.isNotEmpty &&
          body != null &&
          body.isNotEmpty &&
          notification.title == title &&
          notification.body == body;

      if ((payloadMatches || contentMatches) && notification.id != null) {
        await _notifications.cancel(notification.id!);
      }
    }
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
