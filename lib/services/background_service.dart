import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

const String backgroundTaskKey = 'checkin_monitoring_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task");
    
    try {
      // 1. Initialize dependencies
      // Use SharedPreferences directly for "Last Checkin Time".
      final prefs = await SharedPreferences.getInstance();
      
      // Keys must match SharedPrefsService keys
      final lastCheckInStr = prefs.getString('last_checkin_time');
      final interval = prefs.getInt('checkin_interval') ?? 24;
      
      if (lastCheckInStr != null) {
        final lastCheckIn = DateTime.parse(lastCheckInStr);
        final nextCheckIn = lastCheckIn.add(Duration(hours: interval));
        final now = DateTime.now();
        
        if (now.isAfter(nextCheckIn)) {
          // Overdue!
          final notificationService = LocalNotificationService();
          await notificationService.initialize(onNotificationTap: (_) {});
          
          await notificationService.showCheckinReminder(
            title: 'আপনি কি ঠিক আছেন? (Are You Okay?)',
            body: 'আপনার চেক-ইন করার সময় হয়েছে। অনুগ্রহ করে অ্যাপে প্রবেশ করুন।',
            payload: 'checkin_reminder',
          );
        }
      }
      
    } catch (e) {
      print("Background task error: $e");
      return Future.value(false);
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    print("Workmanager initialized");
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      backgroundTaskKey,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected, // changed from not_required to connected or similar
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
     print("Periodic task registered");
  }
}
