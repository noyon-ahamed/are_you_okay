import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart'; // For Color
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';
import '../repository/checkin_repository.dart';
import '../services/api/mood_api_service.dart';
import '../services/api/emergency_api_service.dart';
import '../services/shared_prefs_service.dart';
import '../services/auth/token_storage_service.dart';
import 'mood_local_service.dart';
import 'background_service.dart';
import 'local_notification_history_service.dart';
import 'notification_navigation_service.dart';
import 'notification_service.dart';
import 'notification_sync_service.dart';
import '../provider/language_provider.dart';

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(ref);
});

class OfflineSyncService {
  final Ref ref;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;

  OfflineSyncService(this.ref);

  bool get isOnline => _isOnline;

  Future<void> init() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen to changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOffline && _isOnline) {
        _triggerSync();
      }
    });

    // Try processing if online on init
    if (_isOnline) {
      _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    try {
      // ✅ Auth guard: Skip sync if no user is logged in.
      // Prevents logged-out accounts from triggering notifications
      // or syncing data meant for other users.
      final token = await TokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('Sync skipped — no authenticated user.');
        return;
      }

      debugPrint('Connectivity restored. Triggering sync...');

      // 0. Check and show missed reminders if deadline passed while offline
      await _checkAndShowMissedReminder();

      // 1. Sync pending server clear FIRST (before syncing new check-ins)
      //    This ensures old server data is wiped before new data is pushed.
      await _syncPendingServerClear();

      // 2. Sync pending check-ins
      await ref.read(checkinRepositoryProvider).syncPendingCheckIns();

      // 3. Sync pending contacts
      await EmergencyApiService().syncPendingContacts();

      // 4. Sync pending moods
      await _syncPendingMoods();

      // 5. Surface notifications that arrived while the device was offline
      await NotificationSyncService().syncMissedNotifications(force: true);
    } catch (e) {
      debugPrint('Sync trigger failed: $e');
    }
  }

  /// Checks if check-in deadline passed while offline, and triggers an alert if needed
  Future<void> _checkAndShowMissedReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final repository = ref.read(checkinRepositoryProvider);
      final dbLastCheckIn = repository.getLastCheckIn()?.timestamp;
      final lastCheckInTs = prefs.getInt(AppConstants.keyLastCheckin);
      final prefsLastCheckIn = lastCheckInTs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastCheckInTs)
          : null;
      final lastCheckIn = _latestCheckIn(dbLastCheckIn, prefsLastCheckIn);

      if (lastCheckIn == null) return; // No check-in history

      // The current app flow treats check-in eligibility as a 24 hour window.
      final deadline = lastCheckIn.add(const Duration(hours: 24));
      final now = DateTime.now();
      final missedNotificationId = 'missed-${deadline.millisecondsSinceEpoch}';

      // If deadline has passed
      if (now.isAfter(deadline)) {
        final historyService = LocalNotificationHistoryService();
        final alreadySaved =
            await historyService.containsNotification(missedNotificationId);
        if (alreadySaved) {
          return;
        }

        // Did we already notify recently?
        final lastAlertStr = prefs.getString('last_offline_missed_alert');
        if (lastAlertStr != null) {
          final lastAlert = DateTime.tryParse(lastAlertStr);
          if (lastAlert != null && now.difference(lastAlert).inHours < 12) {
            return; // Don't spam, wait 12h
          }
        }

        debugPrint(
            'Offline sync detected missed check-in deadline. Notifying user.');

        final notificationService = LocalNotificationService();
        final payload = NotificationNavigationService.encodePayload(
          NotificationNavigationService.payloadForReminder(
            notificationId: missedNotificationId,
          ),
        );

        await notificationService.initialize(
          onNotificationTap: NotificationNavigationService.handlePayload,
        );
        final s = ref.read(stringsProvider);
        await notificationService.showNotification(
          id: 888,
          title: s.notifMissedCheckinTitle,
          body: s.notifMissedCheckinBody,
          payload: payload,
          channelId: 'emergency_alerts',
          priority: Priority.max,
        );

        await historyService.saveNotification({
          '_id': missedNotificationId,
          'title': s.notifMissedCheckinTitle,
          'title_en': 'Check-in missed',
          'body': s.notifMissedCheckinHistory,
          'type': 'reminder',
          'payload': payload,
          'createdAt': now.toIso8601String(),
          'source': 'offline_sync',
          'scheduledFor': deadline.toIso8601String(),
        });

        // Record that we alerted
        await prefs.setString(
            'last_offline_missed_alert', now.toIso8601String());

        await BackgroundService.runImmediateReminderCheck();

        // Also post to backend so it appears in App Notification Screen
        final token = await SharedPrefsService.getToken();
        if (token != null) {
          final dio = Dio();
          await dio.post(
            '${AppConstants.apiBaseUrl}/notification',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            data: {
              'title': s.notifMissedDeadlineTitle,
              'title_en': 'Check-in Deadline Missed',
              'body': s.notifMissedDeadlineBody,
              'type': 'alert'
            },
          ).catchError((_) => Response(
              requestOptions:
                  RequestOptions(path: ''))); // ignore backend errors
        }
      }
    } catch (e) {
      debugPrint('Failed to check missed reminder: $e');
    }
  }

  DateTime? _latestCheckIn(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  /// Sends DELETE to server for check-ins & moods when user cleared data offline.
  Future<void> _syncPendingServerClear() async {
    try {
      final prefs = ref.read(sharedPrefsServiceProvider);
      if (!prefs.hasPendingServerClear) return;

      debugPrint('Pending server clear detected. Sending DELETE to server...');

      final token = await SharedPrefsService.getToken();
      if (token == null) {
        debugPrint('No token found, skipping server clear sync.');
        return;
      }

      final pendingUserId = prefs.pendingClearUserId;
      final currentUserId = await TokenStorageService.getUserId();
      if (pendingUserId != null &&
          pendingUserId.isNotEmpty &&
          currentUserId != pendingUserId) {
        debugPrint(
          'Pending server clear belongs to another account. Skipping sync.',
        );
        return;
      }

      final dio = Dio();
      bool checkinCleared = false;
      bool moodCleared = false;

      try {
        await dio
            .delete(
              '${AppConstants.apiBaseUrl}/checkin',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            )
            .timeout(const Duration(seconds: 10));
        checkinCleared = true;
      } catch (e) {
        debugPrint('Server check-in clear failed: $e');
      }

      try {
        await dio
            .delete(
              '${AppConstants.apiBaseUrl}/mood',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            )
            .timeout(const Duration(seconds: 10));
        moodCleared = true;
      } catch (e) {
        debugPrint('Server mood clear failed: $e');
      }

      try {
        await dio
            .delete(
              '${AppConstants.apiBaseUrl}/notification',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            )
            .timeout(const Duration(seconds: 10));
        debugPrint('Server notifications cleared ✓');
      } catch (e) {
        debugPrint('Server notification clear failed (possibly empty): $e');
      }

      if (checkinCleared && moodCleared) {
        // Only remove the flag if both succeeded
        await prefs.setPendingServerClear(false);
        debugPrint('Pending server clear synced successfully ✓');
      } else {
        debugPrint('Server clear partially failed — will retry on next sync.');
      }
    } catch (e) {
      debugPrint('Pending server clear sync error: $e');
    }
  }

  /// Sync pending mood entries to backend
  Future<void> _syncPendingMoods() async {
    try {
      final moodLocal = ref.read(moodLocalServiceProvider);
      final moodApi = MoodApiService();
      final pendingMoods = await moodLocal.getPendingMoods();

      if (pendingMoods.isEmpty) return;

      debugPrint('Syncing ${pendingMoods.length} pending moods...');

      for (final mood in pendingMoods) {
        try {
          await moodApi.saveMood(
            mood: mood['mood'] as String,
            note: mood['note'] as String?,
          );
          await moodLocal.deleteMood(mood['id'] as String);
          debugPrint('Synced mood: ${mood['id']}');
        } catch (e) {
          debugPrint('Failed to sync mood ${mood['id']}: $e');
          // Continue syncing other moods even if one fails
        }
      }
    } catch (e) {
      debugPrint('Mood sync failed: $e');
    }
  }

  /// Manually trigger sync (can be called from UI)
  Future<void> syncNow() async {
    if (_isOnline) {
      await _triggerSync();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
