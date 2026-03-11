import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'notification_service.dart';
import 'local_notification_history_service.dart';
import 'notification_navigation_service.dart';

const String backgroundTaskKey = 'checkin_monitoring_task';

// Keys for SharedPreferences
const String _kLastCheckIn =
    'last_checkin'; // matches AppConstants.keyLastCheckin
const String _kLastDismissed = 'last_notification_dismissed_at';
const String _kNotificationsEnabled = 'notifications_enabled';

const List<_TimeSlot> _dailyReminderSlots = [
  _TimeSlot(id: 201, hour: 9, minute: 0, label: 'সকাল'),
  _TimeSlot(id: 202, hour: 14, minute: 0, label: 'দুপুর'),
  _TimeSlot(id: 203, hour: 21, minute: 0, label: 'রাত'),
];

/// Called by Workmanager in the background isolate.
/// Schedules / cancels the 3 daily reminder notifications.
@pragma('vm:entry-point')
void callbackDispatcher() {
  if (kIsWeb) return;
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task fired: $task');
    try {
      await processReminderCheck();
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
    return Future.value(true);
  });
}

/// Schedule 3 fixed-time daily reminders: 9 AM, 2 PM, 9 PM
/// Uses zonedSchedule with DateTimeComponents.time so they repeat daily.
Future<void> scheduleDailyReminders(
    LocalNotificationService notificationService) async {
  try {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Cancel any old daily reminders first
    await notificationService.cancelDailyReminders();

    for (final slot in _dailyReminderSlots) {
      await notificationService.scheduleDailyNotification(
        id: slot.id,
        title: 'আপনি কি ঠিক আছেন? 🔔',
        body:
            '${slot.label}ের চেক-ইন রিমাইন্ডার। অনুগ্রহ করে অ্যাপে চেক-ইন করুন।',
        hour: slot.hour,
        minute: slot.minute,
        payload: 'daily_checkin_reminder',
      );
    }
    debugPrint('3 daily reminders scheduled (9 AM / 2 PM / 9 PM)');
  } catch (e) {
    debugPrint('Error scheduling daily reminders: $e');
  }
}

Future<void> processReminderCheck() async {
  if (kIsWeb) return;

  final prefs = await SharedPreferences.getInstance();
  final notificationsEnabled = prefs.getBool(_kNotificationsEnabled) ?? true;
  if (!notificationsEnabled) {
    debugPrint('Notifications disabled by user — skipping reminder check');
    return;
  }

  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity == ConnectivityResult.none) {
    debugPrint('No internet — skipping reminder check');
    return;
  }

  final dismissedStr = prefs.getString(_kLastDismissed);
  if (dismissedStr != null) {
    final dismissed = DateTime.tryParse(dismissedStr);
    if (dismissed != null &&
        DateTime.now().difference(dismissed).inHours < 24) {
      debugPrint('User already checked in after reminder — skipping');
      return;
    }
  }

  final lastCheckInTs = prefs.getInt(_kLastCheckIn);
  if (lastCheckInTs != null) {
    final lastCheckIn = DateTime.fromMillisecondsSinceEpoch(lastCheckInTs);
    if (DateTime.now().difference(lastCheckIn).inHours < 24) {
      debugPrint('User checked in within 24h — no reminder needed');
      return;
    }
  }

  final notificationService = LocalNotificationService();
  await notificationService.initialize(
    onNotificationTap: NotificationNavigationService.handlePayload,
  );

  final historyService = LocalNotificationHistoryService();
  final now = DateTime.now();
  final dueSlots = _dailyReminderSlots.where((slot) {
    final scheduledTime =
        DateTime(now.year, now.month, now.day, slot.hour, slot.minute);
    return !scheduledTime.isAfter(now);
  });

  for (final slot in dueSlots) {
    final notificationId = _historyIdForSlot(slot, now);
    if (await historyService.containsNotification(notificationId)) {
      continue;
    }

    final payload = NotificationNavigationService.encodePayload(
      NotificationNavigationService.payloadForReminder(
        notificationId: notificationId,
      ),
    );

    await notificationService.showCheckinReminder(
      title: 'আপনি কি ঠিক আছেন? 🔔',
      body: '${slot.label}ের চেক-ইন রিমাইন্ডার। অনুগ্রহ করে অ্যাপে চেক-ইন করুন।',
      payload: payload,
    );

    await historyService.saveNotification({
      '_id': notificationId,
      'title': 'আপনি কি ঠিক আছেন? 🔔',
      'title_en': 'Are you okay? Reminder',
      'body': '${slot.label}ের চেক-ইন রিমাইন্ডার। অনুগ্রহ করে অ্যাপে চেক-ইন করুন।',
      'type': 'reminder',
      'payload': payload,
      'createdAt': now.toIso8601String(),
      'scheduledFor':
          DateTime(now.year, now.month, now.day, slot.hour, slot.minute)
              .toIso8601String(),
      'notificationId': 1,
      'source': 'background',
    });
  }
}

/// Mark that the user tapped a notification and checked in.
/// This suppresses further reminders for 24 hours.
Future<void> markNotificationDismissed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLastDismissed, DateTime.now().toIso8601String());
  debugPrint('Notification dismissed — suppressing reminders for 24h');

  // Cancel today's remaining reminders
  final notificationService = LocalNotificationService();
  await notificationService.initialize(onNotificationTap: (_) {});
  await notificationService.cancelDailyReminders();
}

class _TimeSlot {
  final int id;
  final int hour;
  final int minute;
  final String label;
  const _TimeSlot(
      {required this.id,
      required this.hour,
      required this.minute,
      required this.label});
}

class BackgroundService {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(callbackDispatcher);
    debugPrint('Workmanager initialized');
  }

  static Future<void> registerPeriodicTask() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      '1',
      backgroundTaskKey,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    debugPrint('Periodic task registered (every 1h)');
  }

  static Future<void> cancelAllTasks() async {
    if (kIsWeb) return;
    await Workmanager().cancelAll();
    debugPrint('All background tasks cancelled');
  }

  static Future<void> runImmediateReminderCheck() async {
    await processReminderCheck();
  }
}

String _historyIdForSlot(_TimeSlot slot, DateTime now) {
  final day = '${now.year}-${now.month}-${now.day}';
  return 'local-$day-${slot.id}';
}
