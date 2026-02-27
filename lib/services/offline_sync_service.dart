import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/checkin_repository.dart';
import '../services/api/mood_api_service.dart';
import 'mood_local_service.dart';

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
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
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
      
      // Sync pending check-ins
      await ref.read(checkinRepositoryProvider).syncPendingCheckIns();
      
      // Sync pending moods
      await _syncPendingMoods();
    } catch (e) {
      debugPrint('Sync trigger failed: $e');
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
