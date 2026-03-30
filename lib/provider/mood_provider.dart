import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/mood_api_service.dart';
import '../services/mood_local_service.dart';

// --- Mood API Provider ---
final moodApiProvider = Provider((ref) => MoodApiService());

List<Map<String, dynamic>> _mergeMoodEntries(
  List<dynamic> remoteHistory,
  List<Map<String, dynamic>> pendingLocal,
) {
  final merged = <Map<String, dynamic>>[];
  final seen = <String>{};

  for (final item in [...pendingLocal, ...remoteHistory]) {
    if (item is! Map) continue;
    final normalized = Map<String, dynamic>.from(item);
    final timestamp = normalized['timestamp']?.toString() ?? '';
    final mood = normalized['mood']?.toString().trim().toLowerCase() ?? '';
    final note = normalized['note']?.toString().trim().toLowerCase() ?? '';
    final key = timestamp.isNotEmpty
        ? 'ts:$timestamp|$mood|$note'
        : 'id:${normalized['_id'] ?? normalized['id'] ?? merged.length}';

    if (seen.add(key)) {
      merged.add(normalized);
    }
  }

  merged.sort((a, b) {
    final aTs = DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bTs = DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return bTs.compareTo(aTs);
  });

  return merged;
}

Map<String, dynamic>? _buildOfflineMoodStats(
    List<Map<String, dynamic>> history) {
  if (history.isEmpty) return null;

  final distribution = <String, int>{};
  for (final entry in history) {
    final mood = entry['mood']?.toString().trim().toLowerCase();
    if (mood == null || mood.isEmpty) continue;
    distribution[mood] = (distribution[mood] ?? 0) + 1;
  }

  return {
    'success': true,
    'stats': {
      'totalEntries': history.length,
      'distribution': distribution,
    },
    'source': 'offline_local',
  };
}

// --- Mood Stats Notifier ---
class MoodStatsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  MoodStatsNotifier(this._api, this._localService)
      : super(const AsyncLoading()) {
    _bootstrap();
  }

  final MoodApiService _api;
  final MoodLocalService _localService;
  Future<void>? _fetchInFlight;

  Future<void> _bootstrap() async {
    final cached = await _api.getCachedStats();
    final fallback = await _buildLocalStatsFallback();
    if (!mounted) return;
    if (fallback != null) {
      state = AsyncData(fallback);
    } else if (cached != null) {
      state = AsyncData(cached);
    }
    await fetch(silent: cached != null || fallback != null);
  }

  Future<void> fetch({bool silent = true}) async {
    if (_fetchInFlight != null) {
      return _fetchInFlight!;
    }

    final future = _fetchStats(silent: silent);
    _fetchInFlight = future;
    try {
      await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<void> _fetchStats({required bool silent}) async {
    if (!silent || !state.hasValue) {
      state = const AsyncLoading();
    }

    try {
      final stats = await _api.getStats(days: 30);
      if (!mounted) return;
      state = AsyncData(stats);
    } catch (e, st) {
      if (!mounted) return;
      final fallback = await _buildLocalStatsFallback();
      if (fallback != null) {
        state = AsyncData(fallback);
      } else if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<Map<String, dynamic>?> _buildLocalStatsFallback() async {
    final cachedHistory = await _api.getCachedHistory();
    final pendingLocal = await _localService.getPendingMoods();
    final historyData = cachedHistory?['moods'] is List
        ? cachedHistory!['moods'] as List
        : <dynamic>[];
    final merged = _mergeMoodEntries(historyData, pendingLocal);
    return _buildOfflineMoodStats(merged);
  }
}

// --- Mood History Notifier ---
class MoodHistoryNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  MoodHistoryNotifier(this._api, this._localService)
      : super(const AsyncLoading()) {
    _bootstrap();
  }

  final MoodApiService _api;
  final MoodLocalService _localService;
  Future<void>? _fetchInFlight;

  Future<void> _bootstrap() async {
    final cached = await _api.getCachedHistory();
    final cachedHistory = await _mergeWithLocal(_extractHistory(cached));
    if (!mounted) return;
    if (cachedHistory.isNotEmpty) {
      state = AsyncData(cachedHistory);
    }
    await fetch(silent: cachedHistory.isNotEmpty);
  }

  Future<void> fetch({bool silent = true}) async {
    if (_fetchInFlight != null) {
      return _fetchInFlight!;
    }

    final future = _fetchHistory(silent: silent);
    _fetchInFlight = future;
    try {
      await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<void> _fetchHistory({required bool silent}) async {
    if (!silent || !state.hasValue) {
      state = const AsyncLoading();
    }

    try {
      final latestCreatedAt = await _api.getLatestHistoryCreatedAt();
      if (!mounted) return;
      final result = await _api.getHistory(
        limit: 50,
        latestCreatedAt: latestCreatedAt,
      );
      if (!mounted) return;
      state = AsyncData(await _mergeWithLocal(_extractHistory(result)));
    } catch (e, st) {
      if (!mounted) return;
      final cached = await _api.getCachedHistory();
      final fallback = await _mergeWithLocal(_extractHistory(cached));
      if (fallback.isNotEmpty) {
        state = AsyncData(fallback);
      } else if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  List<dynamic> _extractHistory(Map<String, dynamic>? result) {
    if (result == null) return <dynamic>[];
    final historyData = result['moods'] ?? result['history'] ?? result['data'];
    if (historyData is List) {
      return historyData;
    }
    return <dynamic>[];
  }

  Future<List<dynamic>> _mergeWithLocal(List<dynamic> remoteHistory) async {
    final pendingLocal = await _localService.getPendingMoods();
    return _mergeMoodEntries(remoteHistory, pendingLocal);
  }
}

// --- Providers ---
final moodStatsProvider =
    StateNotifierProvider<MoodStatsNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) {
  return MoodStatsNotifier(
    ref.watch(moodApiProvider),
    ref.watch(moodLocalServiceProvider),
  );
});

final moodHistoryProvider =
    StateNotifierProvider<MoodHistoryNotifier, AsyncValue<List<dynamic>>>(
        (ref) {
  return MoodHistoryNotifier(
    ref.watch(moodApiProvider),
    ref.watch(moodLocalServiceProvider),
  );
});

/// Provider that calculates the remaining cooldown duration for mood saves.
/// Returns null if no cooldown is active.
final moodCooldownProvider = Provider<Duration?>((ref) {
  final historyAsync = ref.watch(moodHistoryProvider);
  return historyAsync.maybeWhen(
    data: (history) {
      if (history.isEmpty) return null;
      final latest = history.first;
      final timestampStr = latest['timestamp']?.toString();
      if (timestampStr == null) return null;
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null) return null;

      final nextAllowed = timestamp.add(const Duration(hours: 1));
      final diff = nextAllowed.difference(DateTime.now());

      return diff.isNegative ? null : diff;
    },
    orElse: () => null,
  );
});
