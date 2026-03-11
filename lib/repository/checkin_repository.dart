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
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 2));
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
      return checkIn;
    }
  }

  /// Get check-in status from backend
  Future<Map<String, dynamic>> fetchStatus() async {
    try {
      final status = await api.getStatus();
      final merged = _mergeStatusWithLocal(status);
      return merged;
    } catch (e) {
      debugPrint('Failed to fetch status from backend: $e');
      // Fallback to local data
      return _mergeStatusWithLocal(<String, dynamic>{});
    }
  }

  /// Get check-in history from backend
  Future<List<Map<String, dynamic>>> fetchHistory({
    int limit = 30,
    int skip = 0,
  }) async {
    final localHistory = getAllCheckIns().map(_checkinModelToApiMap).toList();
    try {
      final response = await api.getHistory(limit: limit, skip: skip);
      final remote = List<Map<String, dynamic>>.from(response['checkIns'] ?? []);
      final merged = _mergeHistory(remote, localHistory);

      for (final item in remote) {
        final model = _apiMapToCheckinModel(item, isSynced: true);
        if (!_hasLocalEquivalent(model)) {
          await hive.saveCheckIn(model);
        }
      }

      return merged;
    } catch (e) {
      debugPrint('Failed to fetch history from backend: $e');
      return _mergeHistory(<Map<String, dynamic>>[], localHistory);
    }
  }

  /// Sync pending check-ins with server
  Future<void> syncPendingCheckIns() async {
    final pending = hive.getPendingSyncCheckIns();
    if (pending.isEmpty) return;

    debugPrint('Syncing ${pending.length} pending check-ins...');

    for (final checkIn in pending) {
      try {
        await api.checkIn(
          latitude: checkIn.latitude ?? 23.8103,
          longitude: checkIn.longitude ?? 90.4125,
          status: 'safe',
          note: checkIn.notes,
        );
        await hive.markCheckInAsSynced(checkIn.id);
      } catch (e) {
        debugPrint('Failed to sync pending check-in ${checkIn.id}: $e');
      }
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
    final nextCheckIn = lastCheckIn.add(Duration(days: interval));
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

  Map<String, dynamic> _mergeStatusWithLocal(Map<String, dynamic> status) {
    final localLastCheckIn = prefs.lastCheckIn;
    DateTime? remoteLastCheckIn;

    final rawLast = status['lastCheckIn'];
    if (rawLast is Map) {
      remoteLastCheckIn =
          DateTime.tryParse(rawLast['timestamp']?.toString() ?? '');
    } else if (rawLast != null) {
      remoteLastCheckIn = DateTime.tryParse(rawLast.toString());
    }

    final effectiveLast = (localLastCheckIn != null &&
            (remoteLastCheckIn == null ||
                localLastCheckIn.isAfter(remoteLastCheckIn)))
        ? localLastCheckIn
        : remoteLastCheckIn;

    final hoursSince =
        effectiveLast != null ? DateTime.now().difference(effectiveLast).inHours : null;
    final canCheckIn = hoursSince == null || hoursSince >= 24;

    return {
      ...status,
      'lastCheckIn': effectiveLast?.toIso8601String(),
      'hoursSinceLastCheckIn': hoursSince,
      'needsCheckIn': canCheckIn,
      'canCheckIn': canCheckIn,
      'isAtRisk': hoursSince != null && hoursSince >= 72,
      'streak': status['streak'] ?? 0,
    };
  }

  List<Map<String, dynamic>> _mergeHistory(
    List<Map<String, dynamic>> remote,
    List<Map<String, dynamic>> local,
  ) {
    final merged = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    for (final item in [...remote, ...local]) {
      final normalized = Map<String, dynamic>.from(item);
      final key = _historyKey(normalized);
      if (seenKeys.add(key)) {
        merged.add(normalized);
      }
    }

    merged.sort((a, b) {
      final aTime = _parseCheckinTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = _parseCheckinTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  String _historyKey(Map<String, dynamic> item) {
    final dt = _parseCheckinTime(item);
    final epochMinute = dt == null ? 0 : dt.millisecondsSinceEpoch ~/ 60000;
    final lat = (item['latitude'] ?? item['location']?['latitude'] ?? 0).toString();
    final lng =
        (item['longitude'] ?? item['location']?['longitude'] ?? 0).toString();
    return '$epochMinute-$lat-$lng';
  }

  DateTime? _parseCheckinTime(Map<String, dynamic> item) {
    final raw = item['checkInTime'] ?? item['timestamp'] ?? item['createdAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  Map<String, dynamic> _checkinModelToApiMap(CheckInModel model) {
    return {
      'id': model.id,
      'userId': model.userId,
      'checkInTime': model.timestamp.toIso8601String(),
      'timestamp': model.timestamp.toIso8601String(),
      'createdAt': model.createdAt.toIso8601String(),
      'status': 'safe',
      'latitude': model.latitude,
      'longitude': model.longitude,
      'location': {
        'latitude': model.latitude,
        'longitude': model.longitude,
      },
      'isSynced': model.isSynced,
      'notes': model.notes,
    };
  }

  CheckInModel _apiMapToCheckinModel(Map<String, dynamic> item,
      {required bool isSynced}) {
    final timestamp = _parseCheckinTime(item) ?? DateTime.now();
    final latitude =
        (item['latitude'] ?? item['location']?['latitude'] as num?)?.toDouble();
    final longitude =
        (item['longitude'] ?? item['location']?['longitude'] as num?)?.toDouble();
    return CheckInModel(
      id: item['id']?.toString() ?? item['_id']?.toString() ?? _uuid.v4(),
      userId: item['userId']?.toString() ?? item['user']?.toString() ?? '',
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      method: item['method']?.toString() ?? 'button',
      notes: item['notes']?.toString(),
      isSynced: isSynced,
      createdAt:
          DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? timestamp,
    );
  }

  bool _hasLocalEquivalent(CheckInModel candidate) {
    final candidateKey = _historyKey(_checkinModelToApiMap(candidate));
    return hive
        .getAllCheckIns()
        .any((item) => _historyKey(_checkinModelToApiMap(item)) == candidateKey);
  }
}
