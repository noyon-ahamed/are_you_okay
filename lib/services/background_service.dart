import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

const String backgroundTaskKey = 'checkin_monitoring_task';

/// Reminder delivery now comes from backend FCM so notifications still arrive
/// while the app is closed/backgrounded. This service remains as a safe no-op
/// shim for older call sites.
@pragma('vm:entry-point')
void callbackDispatcher() {
  if (kIsWeb) return;
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task fired: $task');
    return Future.value(true);
  });
}

Future<void> scheduleDailyReminders(Object _) async {
  debugPrint('Local daily reminders disabled in favor of backend push.');
}

Future<void> processReminderCheck() async {
  debugPrint('Local reminder catch-up disabled in favor of backend push.');
}

Future<void> markNotificationDismissed() async {
  debugPrint('Reminder dismissal is handled by server-side check-in state.');
}

class BackgroundService {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(callbackDispatcher);
    debugPrint('Workmanager initialized');
  }

  static Future<void> registerPeriodicTask() async {
    debugPrint('Periodic reminder worker disabled in favor of backend push.');
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
