import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
// import 'package:workmanager/workmanager.dart';  // Temporarily disabled
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../model/settings_model.dart';
import '../model/checkin_model.dart';

/// Background Service using Workmanager
/// Handles periodic check-in monitoring
/// TEMPORARILY DISABLED - Workmanager has compatibility issues
class BackgroundService {
  static const String checkinMonitorTask = 'checkin_monitor_task';
  static const String wellnessReminderTask = 'wellness_reminder_task';

  /// Initialize background service
  static Future<void> initialize() async {
    debugPrint('Background service temporarily disabled');
    // await Workmanager().initialize(
    //   callbackDispatcher,
    //   isInDebugMode: kDebugMode,
    // );
    // debugPrint('Background service initialized');
  }

  /// Register check-in monitor task
  static Future<void> registerCheckinMonitor({
    Duration frequency = const Duration(minutes: 15),
  }) async {
    debugPrint('Background tasks temporarily disabled');
    // await Workmanager().registerPeriodicTask(
    //   checkinMonitorTask,
    //   checkinMonitorTask,
    //   frequency: frequency,
    //   constraints: Constraints(
    //     networkType: NetworkType.not_required,
    //     requiresBatteryNotLow: false,
    //     requiresCharging: false,
    //     requiresDeviceIdle: false,
    //     requiresStorageNotLow: false,
    //   ),
    //   backoffPolicy: BackoffPolicy.linear,
    //   backoffPolicyDelay: const Duration(minutes: 15),
    // );
    // debugPrint('Check-in monitor task registered');
  }

  /// Register wellness reminder task
  static Future<void> registerWellnessReminder() async {
    debugPrint('Background tasks temporarily disabled');
    // await Workmanager().registerPeriodicTask(
    //   wellnessReminderTask,
    //   wellnessReminderTask,
    //   frequency: const Duration(hours: 24),
    //   initialDelay: _calculateInitialDelayFor9AM(),
    //   constraints: Constraints(
    //     networkType: NetworkType.not_required,
    //   ),
    // );
    // debugPrint('Wellness reminder task registered');
  }

  /// Cancel all background tasks
  static Future<void> cancelAllTasks() async {
    // await Workmanager().cancelAll();
    debugPrint('Background tasks temporarily disabled');
  }

  /// Cancel specific task
  static Future<void> cancelTask(String taskName) async {
    // await Workmanager().cancelByUniqueName(taskName);
    debugPrint('Background tasks temporarily disabled');
  }

  /// Calculate initial delay to schedule task at 9 AM
  static Duration _calculateInitialDelayFor9AM() {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);

    // If it's already past 9 AM, schedule for tomorrow
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime.difference(now);
  }
}

// TEMPORARILY DISABLED - Workmanager callback dispatcher
/*
/// Callback dispatcher for background tasks
/// This must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task started: $task');

    try {
      switch (task) {
        case BackgroundService.checkinMonitorTask:
          await _handleCheckinMonitor();
          break;
        case BackgroundService.wellnessReminderTask:
          await _handleWellnessReminder();
          break;
        default:
          debugPrint('Unknown task: $task');
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Handle check-in monitor task
Future<void> _handleCheckinMonitor() async {
  try {
    // Initialize Hive (for background access)
    final hiveService = HiveService();
    await hiveService.init();

    // Get user settings
    final settings = hiveService.getSettings();

    // Calculate deadline
    final lastCheckinModel = hiveService.getLastCheckIn();
    if (lastCheckinModel == null) {
      debugPrint('No last check-in found');
      return;
    }
    final lastCheckin = lastCheckinModel.timestamp;

    final intervalHours = settings.checkinIntervalHours;
    final deadline = lastCheckin.add(Duration(hours: intervalHours));
    final now = DateTime.now();

    if (now.isAfter(deadline)) {
      // Deadline passed - send notification
      debugPrint('Check-in deadline passed!');
      
      final notificationService = LocalNotificationService();
      await notificationService.showCheckinReminder(
        title: 'চেক-ইন মিস হয়েছে!',
        body: 'আপনি দীর্ঘ সময় ধরে চেক-ইন করেননি। এখনই চেক-ইন করুন।',
        payload: 'missed_checkin',
      );

      // Note: Alert to emergency contacts would be handled by Firebase Cloud Function
    } else {
      // Calculate time remaining
      final timeLeft = deadline.difference(now);
      
      // Send reminder notifications at specific intervals
      if (timeLeft.inHours == 6) {
        final notificationService = LocalNotificationService();
        await notificationService.showCheckinReminder(
          title: 'চেক-ইন রিমাইন্ডার',
          body: '৬ ঘণ্টার মধ্যে চেক-ইন করুন।',
        );
      } else if (timeLeft.inHours == 2) {
        final notificationService = LocalNotificationService();
        await notificationService.showCheckinReminder(
          title: 'চেক-ইন রিমাইন্ডার',
          body: '২ ঘণ্টার মধ্যে চেক-ইন করুন।',
        );
      } else if (timeLeft.inMinutes == 30) {
        final notificationService = LocalNotificationService();
        await notificationService.showCheckinReminder(
          title: 'জরুরি চেক-ইন রিমাইন্ডার',
          body: '৩০ মিনিটের মধ্যে চেক-ইন করুন!',
        );
      }
    }
  } catch (e) {
    debugPrint('Error in check-in monitor: $e');
  }
}

/// Handle wellness reminder task
Future<void> _handleWellnessReminder() async {
  try {
    final notificationService = LocalNotificationService();
    await notificationService.showNotification(
      id: 999,
      title: 'সুপ্রভাত! 🌅',
      body: 'আজকের দিন শুভ হোক। আপনি ভালো আছেন তো?',
      channelId: 'info_updates',
    );
  } catch (e) {
    debugPrint('Error in wellness reminder: $e');
  }
}
*/
