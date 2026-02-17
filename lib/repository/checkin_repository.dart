import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/checkin_model.dart';
import '../services/hive_service.dart';
import '../services/shared_prefs_service.dart';
import '../services/socket_service.dart';

final checkinRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(
    hive: ref.watch(hiveServiceProvider),
    prefs: ref.watch(sharedPrefsServiceProvider),
    socketService: ref.watch(socketServiceProvider),
  );
});

class CheckInRepository {
  final HiveService hive;
  final SharedPrefsService prefs;
  final SocketService socketService;
  final _uuid = const Uuid();

  CheckInRepository({
    required this.hive,
    required this.prefs,
    required this.socketService,
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

      // Save locally first (Optimistic UI)
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

      // Try to sync immediately
      if (socketService.isConnected) {
        socketService.emitCheckIn(checkIn.toJson());
        
        // Let's optimistically mark synced if connected.
        await hive.markCheckInAsSynced(checkIn.id);
        
        // Return synced version
        return checkIn.copyWith(isSynced: true);
      }

      return checkIn; // Return un-synced version
    } catch (e) {
      throw Exception('Failed to perform check-in: $e');
    }
  }

  // ... (getters omitted for brevity, they remain same) ...

  /// Sync pending check-ins with server
  Future<void> syncPendingCheckIns() async {
    try {
      if (!socketService.isConnected) {
        await socketService.init(); // Try to connect if not
      }

      if (!socketService.isConnected) return; // Still offline

      final pending = hive.getPendingSyncCheckIns();
      if (pending.isEmpty) return;

      print('Syncing ${pending.length} pending check-ins...');
      
      for (final checkIn in pending) {
        socketService.emitCheckIn(checkIn.toJson());
        // Mark as synced
        await hive.markCheckInAsSynced(checkIn.id);
      }
    } catch (e) {
      throw Exception('Failed to sync check-ins: $e');
    }
  }

  /// Get all check-ins
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
      return 0; // Overdue
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