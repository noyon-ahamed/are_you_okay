import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _historyCacheKey = 'checkin_history_cache_v1';
  static const String _historyMetaKey = 'checkin_history_cache_meta_v1';
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
    final performedAt = DateTime.now();
    final existingLocal = _findExistingCheckInAround(performedAt);
    if (existingLocal != null) {
      await prefs.setLastCheckIn(existingLocal.timestamp);
      return existingLocal;
    }

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
        timestamp: performedAt,
      );

      final payload = _extractCheckInPayload(response);
      final resolvedTimestamp = _parseCheckinTime(payload) ?? performedAt;
      final checkIn = CheckInModel(
        id: payload['_id']?.toString() ??
            payload['id']?.toString() ??
            _uuid.v4(),
        userId:
            payload['user']?.toString() ?? payload['userId']?.toString() ?? '',
        timestamp: resolvedTimestamp,
        latitude: lat,
        longitude: lng,
        method: method,
        notes: notes,
        isSynced: true,
        createdAt: DateTime.tryParse(payload['createdAt']?.toString() ?? '') ??
            resolvedTimestamp,
      );

      await _persistCanonicalCheckIn(checkIn);
      await prefs.setLastCheckIn(checkIn.timestamp);

      return checkIn;
    } on AlreadyCheckedInException catch (e) {
      final canonical = _resolveExistingCheckIn(
        existingPayload: e.existingCheckIn,
        fallbackTime: performedAt,
        latitude: lat,
        longitude: lng,
        method: method,
        notes: notes,
      );
      await _persistCanonicalCheckIn(canonical);
      await prefs.setLastCheckIn(canonical.timestamp);
      return canonical;
    } catch (e) {
      debugPrint('Backend check-in failed, saving locally: $e');

      // Fallback: save locally for later sync
      final user = hive.getCurrentUser();
      final checkIn = CheckInModel(
        id: _uuid.v4(),
        userId: user?.id ?? 'offline',
        timestamp: performedAt,
        latitude: lat,
        longitude: lng,
        method: method,
        notes: notes,
        isSynced: false,
        createdAt: performedAt,
      );

      await _persistCanonicalCheckIn(checkIn);
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
    final localHistory = getAllCheckIns().map(checkinModelToApiMap).toList();
    try {
      final response = await api.getHistory(
        limit: limit,
        skip: skip,
        latestCreatedAt: await getLatestHistoryCreatedAt(),
      );
      final remote =
          List<Map<String, dynamic>>.from(response['checkIns'] ?? []);
      final cachedHistory = await getCachedHistory();
      final merged =
          mergeHistory(remote, mergeHistory(cachedHistory, localHistory));

      for (final item in remote) {
        final model = _apiMapToCheckinModel(item, isSynced: true);
        await _persistCanonicalCheckIn(model);
      }

      await _saveHistoryCache(merged);
      await _setLatestHistoryCreatedAt(
        response['sync']?['latestCreatedAt']?.toString(),
        merged,
      );

      return merged;
    } catch (e) {
      debugPrint('Failed to fetch history from backend: $e');
      final cachedHistory = await getCachedHistory();
      return mergeHistory(cachedHistory, localHistory);
    }
  }

  Future<List<Map<String, dynamic>>> getCachedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyCacheKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<String?> getLatestHistoryCreatedAt() async {
    final cached = await getCachedHistory();
    if (cached.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyMetaKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['latestCreatedAt']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Sync pending check-ins with server
  Future<void> syncPendingCheckIns() async {
    final pending = hive.getPendingSyncCheckIns()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (pending.isEmpty) return;

    debugPrint('Syncing ${pending.length} pending check-ins...');

    List<Map<String, dynamic>> remoteHistory = <Map<String, dynamic>>[];
    try {
      final response = await api.getHistory(limit: 100, skip: 0);
      remoteHistory =
          List<Map<String, dynamic>>.from(response['checkIns'] ?? []);
    } catch (e) {
      debugPrint('Unable to preload remote check-in history: $e');
    }

    for (final checkIn in pending) {
      final localMap = checkinModelToApiMap(checkIn);

      if (remoteHistory.any((item) => _isSameLogicalCheckIn(item, localMap))) {
        final remoteMatch = remoteHistory.firstWhere(
          (item) => _isSameLogicalCheckIn(item, localMap),
        );
        final canonical = _apiMapToCheckinModel(remoteMatch, isSynced: true);
        await _persistCanonicalCheckIn(canonical);
        continue;
      }

      try {
        final response = await api.checkIn(
          latitude: checkIn.latitude ?? 23.8103,
          longitude: checkIn.longitude ?? 90.4125,
          status: 'safe',
          note: checkIn.notes,
          timestamp: checkIn.timestamp,
          clientGeneratedId: checkIn.id,
        );
        final syncedModel = _buildSyncedCheckIn(checkIn, response);
        await _persistCanonicalCheckIn(syncedModel);
        remoteHistory.insert(0, checkinModelToApiMap(syncedModel));
      } on AlreadyCheckedInException catch (e) {
        final canonical = _resolveExistingCheckIn(
          existingPayload: e.existingCheckIn,
          fallbackTime: checkIn.timestamp,
          latitude: checkIn.latitude ?? 23.8103,
          longitude: checkIn.longitude ?? 90.4125,
          method: checkIn.method,
          notes: checkIn.notes,
        );
        await _persistCanonicalCheckIn(canonical);
        remoteHistory.insert(0, checkinModelToApiMap(canonical));
      } catch (e) {
        if (_isAlreadyCheckedInError(e)) {
          await hive.deleteCheckIn(checkIn.id);
          continue;
        }
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

    final hoursSince = effectiveLast != null
        ? DateTime.now().difference(effectiveLast).inHours
        : null;
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

  List<Map<String, dynamic>> mergeHistory(
    List<Map<String, dynamic>> remote,
    List<Map<String, dynamic>> local,
  ) {
    final merged = <Map<String, dynamic>>[];
    final combined = [...remote, ...local]..sort((a, b) {
        final aTime =
            _parseCheckinTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            _parseCheckinTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

    for (final item in combined) {
      final normalized = Map<String, dynamic>.from(item);
      final existingIndex = merged.indexWhere(
        (entry) => _isSameLogicalCheckIn(entry, normalized),
      );
      if (existingIndex == -1) {
        merged.add(normalized);
      } else {
        merged[existingIndex] =
            _mergeHistoryEntry(merged[existingIndex], normalized);
      }
    }

    merged.sort((a, b) {
      final aTime =
          _parseCheckinTime(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          _parseCheckinTime(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  DateTime? _parseCheckinTime(Map<String, dynamic> item) {
    final raw = item['checkInTime'] ?? item['timestamp'] ?? item['createdAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  Map<String, dynamic> checkinModelToApiMap(CheckInModel model) {
    return {
      'id': model.id,
      'userId': model.userId,
      'clientGeneratedId': model.id,
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
        (item['longitude'] ?? item['location']?['longitude'] as num?)
            ?.toDouble();
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

  Map<String, dynamic> _extractCheckInPayload(Map<String, dynamic> response) {
    final raw = response['checkIn'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  CheckInModel _buildSyncedCheckIn(
    CheckInModel localCheckIn,
    Map<String, dynamic> response,
  ) {
    final payload = _extractCheckInPayload(response);
    final syncedTimestamp =
        _parseCheckinTime(payload) ?? localCheckIn.timestamp;
    final syncedLatitude =
        (payload['latitude'] ?? payload['location']?['latitude'] as num?)
            ?.toDouble();
    final syncedLongitude =
        (payload['longitude'] ?? payload['location']?['longitude'] as num?)
            ?.toDouble();

    return localCheckIn.copyWith(
      id: payload['_id']?.toString() ??
          payload['id']?.toString() ??
          localCheckIn.id,
      userId: payload['user']?.toString() ??
          payload['userId']?.toString() ??
          localCheckIn.userId,
      timestamp: syncedTimestamp,
      latitude: syncedLatitude ?? localCheckIn.latitude,
      longitude: syncedLongitude ?? localCheckIn.longitude,
      notes: payload['note']?.toString() ??
          payload['notes']?.toString() ??
          localCheckIn.notes,
      isSynced: true,
      createdAt: DateTime.tryParse(payload['createdAt']?.toString() ?? '') ??
          localCheckIn.createdAt,
    );
  }

  bool _isAlreadyCheckedInError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('already checked in today') ||
        message.contains('already checked in');
  }

  bool _isSameLogicalCheckIn(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    if (_sameNonEmptyValue(
      _extractClientGeneratedId(first),
      _extractClientGeneratedId(second),
    )) {
      return true;
    }

    if (_sameNonEmptyValue(_extractStableId(first), _extractStableId(second))) {
      return true;
    }

    final firstTime = _parseCheckinTime(first);
    final secondTime = _parseCheckinTime(second);
    if (firstTime == null || secondTime == null) {
      return false;
    }

    final firstUserId = _extractUserId(first);
    final secondUserId = _extractUserId(second);
    if (_hasMeaningfulValue(firstUserId) &&
        _hasMeaningfulValue(secondUserId) &&
        firstUserId != secondUserId) {
      return false;
    }

    final timeDifference = firstTime.difference(secondTime).abs();
    return timeDifference < const Duration(hours: 24);
  }

  Map<String, dynamic> _mergeHistoryEntry(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) {
    final existingTime = _parseCheckinTime(existing);
    final incomingTime = _parseCheckinTime(incoming);
    final preferIncoming = existingTime == null ||
        (incomingTime != null && incomingTime.isBefore(existingTime));

    final preferred =
        Map<String, dynamic>.from(preferIncoming ? incoming : existing);
    final secondary =
        Map<String, dynamic>.from(preferIncoming ? existing : incoming);

    const fields = <String>[
      '_id',
      'id',
      'user',
      'userId',
      'method',
      'status',
      'notes',
      'note',
      'checkInTime',
      'timestamp',
      'createdAt',
      'clientGeneratedId',
    ];

    for (final field in fields) {
      if (!_hasMeaningfulValue(preferred[field]) &&
          _hasMeaningfulValue(secondary[field])) {
        preferred[field] = secondary[field];
      }
    }

    if ((preferred['isSynced'] != true) && secondary['isSynced'] == true) {
      preferred['isSynced'] = true;
      preferred['_id'] ??= secondary['_id'];
      preferred['id'] ??= secondary['id'];
    } else {
      preferred['isSynced'] =
          preferred['isSynced'] == true || secondary['isSynced'] == true;
    }

    final preferredLat =
        preferred['latitude'] ?? preferred['location']?['latitude'];
    final preferredLng =
        preferred['longitude'] ?? preferred['location']?['longitude'];
    if (preferredLat == null || preferredLng == null) {
      final secondaryLocation = secondary['location'];
      if (secondaryLocation is Map) {
        preferred['location'] ??= Map<String, dynamic>.from(secondaryLocation);
      }
      preferred['latitude'] ??= secondary['latitude'];
      preferred['longitude'] ??= secondary['longitude'];
    }

    return preferred;
  }

  bool _hasMeaningfulValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return true;
  }

  Future<void> _persistCanonicalCheckIn(CheckInModel canonical) async {
    final canonicalMap = checkinModelToApiMap(canonical);
    for (final item in hive.getAllCheckIns()) {
      if (item.id == canonical.id) continue;
      if (_isSameLogicalCheckIn(checkinModelToApiMap(item), canonicalMap)) {
        await hive.deleteCheckIn(item.id);
      }
    }
    await hive.saveCheckIn(canonical);
  }

  CheckInModel? _findExistingCheckInAround(DateTime timestamp) {
    for (final item in hive.getAllCheckIns()) {
      final difference = item.timestamp.difference(timestamp).abs();
      if (difference < const Duration(hours: 24)) {
        return item;
      }
    }
    return null;
  }

  CheckInModel _resolveExistingCheckIn({
    required Map<String, dynamic>? existingPayload,
    required DateTime fallbackTime,
    required double latitude,
    required double longitude,
    required String method,
    required String? notes,
  }) {
    if (existingPayload != null && existingPayload.isNotEmpty) {
      return _apiMapToCheckinModel(existingPayload, isSynced: true);
    }

    final localExisting = _findExistingCheckInAround(fallbackTime);
    if (localExisting != null) {
      return localExisting.copyWith(isSynced: true);
    }

    final user = hive.getCurrentUser();
    return CheckInModel(
      id: _uuid.v4(),
      userId: user?.id ?? '',
      timestamp: fallbackTime,
      latitude: latitude,
      longitude: longitude,
      method: method,
      notes: notes,
      isSynced: true,
      createdAt: fallbackTime,
    );
  }

  String? _extractStableId(Map<String, dynamic> item) {
    return item['_id']?.toString() ?? item['id']?.toString();
  }

  String? _extractClientGeneratedId(Map<String, dynamic> item) {
    return item['clientGeneratedId']?.toString();
  }

  String? _extractUserId(Map<String, dynamic> item) {
    return item['userId']?.toString() ?? item['user']?.toString();
  }

  bool _sameNonEmptyValue(String? first, String? second) {
    return _hasMeaningfulValue(first) &&
        _hasMeaningfulValue(second) &&
        first == second;
  }

  Future<void> _saveHistoryCache(List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyCacheKey, jsonEncode(history));
  }

  Future<void> _setLatestHistoryCreatedAt(
    String? latestCreatedAt,
    List<Map<String, dynamic>> history,
  ) async {
    final resolved = latestCreatedAt ?? _findLatestHistoryTimestamp(history);
    if (resolved == null || resolved.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyMetaKey,
      jsonEncode({'latestCreatedAt': resolved}),
    );
  }

  String? _findLatestHistoryTimestamp(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return null;
    return history
        .map(_parseCheckinTime)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, current) {
      if (latest == null || current.isAfter(latest)) {
        return current;
      }
      return latest;
    })?.toIso8601String();
  }
}
