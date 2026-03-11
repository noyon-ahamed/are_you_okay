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
import 'mood_local_service.dart';
import 'background_service.dart';
import 'local_notification_history_service.dart';
import 'notification_navigation_service.dart';
import 'notification_service.dart';

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
    } catch (e) {
      debugPrint('Sync trigger failed: $e');
    }
  }

  /// Checks if check-in deadline passed while offline, and triggers an alert if needed
  Future<void> _checkAndShowMissedReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckInTs = prefs.getInt(AppConstants.keyLastCheckin);
      final intervalDays = prefs.getInt(AppConstants.keyCheckinInterval) ??
          AppConstants.defaultCheckinIntervalDays;

      if (lastCheckInTs == null) return; // No check-in history

      final lastCheckIn = DateTime.fromMillisecondsSinceEpoch(lastCheckInTs);

      final deadline = lastCheckIn.add(Duration(days: intervalDays));
      final now = DateTime.now();

      // If deadline has passed
      if (now.isAfter(deadline)) {
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
            notificationId:
                'missed-${now.year}-${now.month}-${now.day}-${deadline.millisecondsSinceEpoch}',
          ),
        );

        await notificationService.initialize(
          onNotificationTap: NotificationNavigationService.handlePayload,
        );
        await notificationService.showNotification(
          id: 888,
          title: '🚨 চেক-ইন মিস করেছেন!',
          body:
              'আপনার চেক-ইনের সময় পার হয়ে গেছে। অনুগ্রহ করে এখনই চেক-ইন করুন যাতে আপনার জরুরি যোগাযোগদের সতর্ক করা না হয়।',
          payload: payload,
          channelId: 'emergency_alerts',
          priority: Priority.max,
        );

        await LocalNotificationHistoryService().saveNotification({
          '_id':
              'missed-${now.year}-${now.month}-${now.day}-${deadline.millisecondsSinceEpoch}',
          'title': '🚨 চেক-ইন মিস করেছেন!',
          'title_en': 'Check-in missed',
          'body':
              'আপনার চেক-ইনের সময় পার হয়ে গেছে। অনুগ্রহ করে এখনই চেক-ইন করুন।',
          'type': 'reminder',
          'payload': payload,
          'createdAt': now.toIso8601String(),
          'source': 'offline_sync',
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
              'title': 'চেক-ইন ডেডলাইন পার হয়েছে',
              'title_en': 'Check-in Deadline Missed',
              'body':
                  'আপনি অনেকক্ষণ ধরে অ্যাপে আসেননি। অনুগ্রহ করে চেক-ইন করুন।',
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
      final pendingMoods = moodLocal.getPendingMoods();

      if (pendingMoods.isEmpty) return;

      debugPrint('Syncing ${pendingMoods.length} pending moods...');

      for (final mood in pendingMoods) {
        try {
          await moodApi.saveMood(
            mood: mood['mood'] as String,
            note: mood['note'] as String?,
          );
          await moodLocal.markMoodAsSynced(mood['id'] as String);
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
