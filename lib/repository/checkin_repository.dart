import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../model/checkin_model.dart';
import '../services/api/checkin_api_service.dart';
import '../services/hive_service.dart';
import '../services/shared_prefs_service.dart';
import '../services/socket_service.dart';

final checkinRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(
    hive: ref.watch(hiveServiceProvider),
    prefs: ref.watch(sharedPrefsServiceProvider),
    socketService: ref.watch(socketServiceProvider),
    api: CheckinApiService(),
  );
});

class CheckInRepository {
  final HiveService hive;
  final SharedPrefsService prefs;
  final SocketService socketService;
  final CheckinApiService api;
  final _uuid = const Uuid();

  CheckInRepository({
    required this.hive,
    required this.prefs,
    required this.socketService,
    required this.api,
  });

  /// Perform check-in — calls backend API, falls back to local storage
  Future<CheckInModel> performCheckIn({
    double? latitude,
    double? longitude,
    String method = 'button',
    String? notes,
  }) async {
    // Get location if not provided
    double lat = latitude ?? 23.8103;
    double lng = longitude ?? 90.4125;
    
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      debugPrint('Location error (using default): $e');
    }

    try {
      // Try backend API first
      final response = await api.checkIn(
        latitude: lat,
        longitude: lng,
        status: 'safe',
        note: notes,
      );

      final checkIn = CheckInModel(
        id: response['checkIn']?['_id'] ?? _uuid.v4(),
        userId: response['checkIn']?['user'] ?? response['checkIn']?['userId'] ?? '',
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
        method: method,
        notes: notes,
        isSynced: true,
        createdAt: DateTime.now(),
      );

      // Cache locally
      await hive.saveCheckIn(checkIn);
      await prefs.setLastCheckIn(checkIn.timestamp);

      return checkIn;
    } catch (e) {
      debugPrint('Backend check-in failed, saving locally: $e');

      // Fallback: save locally for later sync
      final user = hive.getCurrentUser();
      final checkIn = CheckInModel(
        id: _uuid.v4(),
        userId: user?.id ?? 'offline',
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
        method: method,
        notes: notes,
        isSynced: false,
        createdAt: DateTime.now(),
      );

      await hive.saveCheckIn(checkIn);
      await prefs.setLastCheckIn(checkIn.timestamp);

      // Try socket sync
      if (socketService.isConnected) {
        socketService.emitCheckIn(checkIn.toJson());
        await hive.markCheckInAsSynced(checkIn.id);
        return checkIn.copyWith(isSynced: true);
      }

      return checkIn;
    }
  }

  /// Get check-in status from backend
  Future<Map<String, dynamic>> fetchStatus() async {
    try {
      final status = await api.getStatus();
      return status;
    } catch (e) {
      debugPrint('Failed to fetch status from backend: $e');
      // Fallback to local data
      final lastCheckIn = prefs.lastCheckIn;
      final hoursSince = lastCheckIn != null
          ? DateTime.now().difference(lastCheckIn).inHours
          : null;

      return {
        'lastCheckIn': lastCheckIn?.toIso8601String(),
        'hoursSinceLastCheckIn': hoursSince,
        'needsCheckIn': hoursSince == null || hoursSince >= 24,
        'streak': 0,
        'isAtRisk': hoursSince != null && hoursSince >= 72,
      };
    }
  }

  /// Get check-in history from backend
  Future<List<Map<String, dynamic>>> fetchHistory({
    int limit = 30,
    int skip = 0,
  }) async {
    try {
      final response = await api.getHistory(limit: limit, skip: skip);
      return List<Map<String, dynamic>>.from(response['checkIns'] ?? []);
    } catch (e) {
      debugPrint('Failed to fetch history from backend: $e');
      // Fallback to local
      return getAllCheckIns().map((c) => c.toJson()).toList();
    }
  }

  /// Sync pending check-ins with server
  Future<void> syncPendingCheckIns() async {
    try {
      if (!socketService.isConnected) {
        await socketService.init();
      }

      if (!socketService.isConnected) return;

      final pending = hive.getPendingSyncCheckIns();
      if (pending.isEmpty) return;

      debugPrint('Syncing ${pending.length} pending check-ins...');

      for (final checkIn in pending) {
        socketService.emitCheckIn(checkIn.toJson());
        await hive.markCheckInAsSynced(checkIn.id);
      }
    } catch (e) {
      debugPrint('Failed to sync check-ins: $e');
    }
  }

  /// Get all local check-ins
  List<CheckInModel> getAllCheckIns() {
    return hive.getAllCheckIns();
  }

  /// Get last check-in
  CheckInModel? getLastCheckIn() {
    return hive.getLastCheckIn();
  }

  /// Get hours until next check-in
  int getHoursUntilNextCheckIn() {
    final lastCheckIn = prefs.lastCheckIn;
    if (lastCheckIn == null) return 0;

    final interval = prefs.checkinInterval;
    final nextCheckIn = lastCheckIn.add(Duration(hours: interval));
    final now = DateTime.now();

    if (now.isAfter(nextCheckIn)) {
      return 0;
    }

    return nextCheckIn.difference(now).inHours;
  }

  /// Get check-in statistics
  Map<String, dynamic> getCheckInStats() {
    final all = hive.getAllCheckIns();

    return {
      'total': all.length,
      'thisWeek': all.where((c) {
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return c.timestamp.isAfter(weekAgo);
      }).length,
      'thisMonth': all.where((c) {
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        return c.timestamp.isAfter(monthAgo);
      }).length,
    };
  }
}