import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/checkin_repository.dart';

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(ref);
});

class OfflineSyncService {
  final Ref ref;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;

  OfflineSyncService(this.ref);

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
      print('Connectivity restored. Triggering sync...');
      await ref.read(checkinRepositoryProvider).syncPendingCheckIns();
      // Add other sync calls here (e.g. mood, contacts)
    } catch (e) {
      print('Sync trigger failed: $e');
    }
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
