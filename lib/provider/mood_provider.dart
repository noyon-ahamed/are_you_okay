import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/mood_api_service.dart';

// --- Mood API Provider ---
final moodApiProvider = Provider((ref) => MoodApiService());

// --- Mood Stats Notifier ---
class MoodStatsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  MoodStatsNotifier(this._api) : super(const AsyncLoading()) {
    _bootstrap();
  }

  final MoodApiService _api;
  Future<void>? _fetchInFlight;

  Future<void> _bootstrap() async {
    final cached = await _api.getCachedStats();
    if (!mounted) return;
    if (cached != null) {
      state = AsyncData(cached);
    }
    await fetch(silent: cached != null);
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
      if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }
}

// --- Mood History Notifier ---
class MoodHistoryNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  MoodHistoryNotifier(this._api) : super(const AsyncLoading()) {
    _bootstrap();
  }

  final MoodApiService _api;
  Future<void>? _fetchInFlight;

  Future<void> _bootstrap() async {
    final cached = await _api.getCachedHistory();
    final cachedHistory = _extractHistory(cached);
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
      state = AsyncData(_extractHistory(result));
    } catch (e, st) {
      if (!mounted) return;
      if (!silent || !state.hasValue) {
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
}

// --- Providers ---
final moodStatsProvider =
    StateNotifierProvider<MoodStatsNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) {
  return MoodStatsNotifier(ref.watch(moodApiProvider));
});

final moodHistoryProvider =
    StateNotifierProvider<MoodHistoryNotifier, AsyncValue<List<dynamic>>>(
        (ref) {
  return MoodHistoryNotifier(ref.watch(moodApiProvider));
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
