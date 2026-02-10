import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/checkin_model.dart';
import '../model/user_model.dart';
import '../services/hive_service.dart';
import '../services/shared_prefs_service.dart';
import 'auth_repository.dart';

final checkinRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(
    hive: ref.watch(hiveServiceProvider),
    prefs: ref.watch(sharedPrefsServiceProvider),
  );
});

class CheckInRepository {
  final HiveService hive;
  final SharedPrefsService prefs;
  final _uuid = const Uuid();

  CheckInRepository({
    required this.hive,
    required this.prefs,
  });

  /// Perform check-in
  Future<CheckInModel> performCheckIn({
    double? latitude,
    double? longitude,
    String method = 'button',
    String? notes,
  }) async {
    try {
      final user = hive.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final checkIn = CheckInModel(
        id: _uuid.v4(),
        userId: user.id,
        timestamp: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        method: method,
        notes: notes,
        isSynced: false,
        createdAt: DateTime.now(),
      );

      // Save locally
      await hive.saveCheckIn(checkIn);
      
      // Update last check-in time
      await prefs.setLastCheckIn(checkIn.timestamp);
      
      // Update user's last check-in
      await hive.updateUser(
        user.copyWith(
          lastCheckIn: checkIn.timestamp,
          updatedAt: DateTime.now(),
        ),
      );

      // TODO: Sync with Firebase in background

      return checkIn;
    } catch (e) {
      throw Exception('Failed to perform check-in: $e');
    }
  }

  /// Get all check-ins
  List<CheckInModel> getAllCheckIns() {
    return hive.getAllCheckIns();
  }

  /// Get recent check-ins
  List<CheckInModel> getRecentCheckIns({int limit = 10}) {
    return hive.getRecentCheckIns(limit: limit);
  }

  /// Get last check-in
  CheckInModel? getLastCheckIn() {
    return hive.getLastCheckIn();
  }

  /// Get time until next check-in (in hours)
  int? getHoursUntilNextCheckIn() {
    final lastCheckIn = getLastCheckIn();
    if (lastCheckIn == null) return null;

    final interval = prefs.checkinInterval;
    final nextCheckIn = lastCheckIn.timestamp.add(Duration(hours: interval));
    final now = DateTime.now();

    if (now.isAfter(nextCheckIn)) {
      return 0; // Overdue
    }

    final difference = nextCheckIn.difference(now);
    return difference.inHours;
  }

  /// Check if check-in is overdue
  bool isCheckInOverdue() {
    final hours = getHoursUntilNextCheckIn();
    return hours != null && hours <= 0;
  }

  /// Get minutes until next check-in
  int? getMinutesUntilNextCheckIn() {
    final lastCheckIn = getLastCheckIn();
    if (lastCheckIn == null) return null;

    final interval = prefs.checkinInterval;
    final nextCheckIn = lastCheckIn.timestamp.add(Duration(hours: interval));
    final now = DateTime.now();

    if (now.isAfter(nextCheckIn)) {
      return 0; // Overdue
    }

    final difference = nextCheckIn.difference(now);
    return difference.inMinutes;
  }

  /// Delete check-in
  Future<void> deleteCheckIn(String id) async {
    await hive.deleteCheckIn(id);
  }

  /// Sync pending check-ins with server
  Future<void> syncPendingCheckIns() async {
    try {
      final pending = hive.getPendingSyncCheckIns();
      
      for (final checkIn in pending) {
        // TODO: Upload to Firebase
        
        // Mark as synced
        await hive.markCheckInAsSynced(checkIn.id);
      }
    } catch (e) {
      throw Exception('Failed to sync check-ins: $e');
    }
  }

  /// Get check-in statistics
  Map<String, dynamic> getCheckInStats() {
    final all = getAllCheckIns();
    
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