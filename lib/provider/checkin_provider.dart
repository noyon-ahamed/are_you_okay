import 'dart:async';
import 'package:are_you_okay/services/auth/token_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/checkin_model.dart';
import '../repository/checkin_repository.dart';
import '../services/api/auth_api_service.dart';
import '../services/shared_prefs_service.dart';

// ==================== Check-In Action State ====================

abstract class CheckInState {
  const CheckInState();
}

class CheckInInitial extends CheckInState {
  const CheckInInitial();
}

class CheckInLoading extends CheckInState {
  const CheckInLoading();
}

class CheckInSuccess extends CheckInState {
  final CheckInModel checkIn;
  const CheckInSuccess(this.checkIn);
}

class CheckInError extends CheckInState {
  final String message;
  const CheckInError(this.message);
}

// ==================== Check-In Status (from backend) ====================

class CheckInStatusData {
  final DateTime? lastCheckIn;
  final int? hoursSinceLastCheckIn;
  final bool needsCheckIn;
  final bool canCheckIn;
  final DateTime? nextCheckInTime;
  final int streak;
  final bool isAtRisk;
  final bool isLoading;
  final String? error;

  const CheckInStatusData({
    this.lastCheckIn,
    this.hoursSinceLastCheckIn,
    this.needsCheckIn = true,
    this.canCheckIn = true,
    this.nextCheckInTime,
    this.streak = 0,
    this.isAtRisk = false,
    this.isLoading = false,
    this.error,
  });

  /// Time remaining until next check-in is allowed (from server's nextCheckInTime)
  Duration get timeRemaining {
    if (nextCheckInTime == null) {
      if (lastCheckIn == null) return Duration.zero;
      // Fallback: use lastCheckIn + 24h
      final fallbackNext = lastCheckIn!.add(const Duration(hours: 24));
      final now = DateTime.now();
      if (now.isAfter(fallbackNext)) return Duration.zero;
      return fallbackNext.difference(now);
    }
    final now = DateTime.now();
    if (now.isAfter(nextCheckInTime!)) return Duration.zero;
    return nextCheckInTime!.difference(now);
  }

  /// Whether user has already checked in (within 24h window)
  bool get hasCheckedInToday => !canCheckIn;

  CheckInStatusData copyWith({
    DateTime? lastCheckIn,
    int? hoursSinceLastCheckIn,
    bool? needsCheckIn,
    bool? canCheckIn,
    DateTime? nextCheckInTime,
    int? streak,
    bool? isAtRisk,
    bool? isLoading,
    String? error,
  }) {
    return CheckInStatusData(
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      hoursSinceLastCheckIn:
          hoursSinceLastCheckIn ?? this.hoursSinceLastCheckIn,
      needsCheckIn: needsCheckIn ?? this.needsCheckIn,
      canCheckIn: canCheckIn ?? this.canCheckIn,
      nextCheckInTime: nextCheckInTime ?? this.nextCheckInTime,
      streak: streak ?? this.streak,
      isAtRisk: isAtRisk ?? this.isAtRisk,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ==================== Check-In Notifier ====================

class CheckInNotifier extends StateNotifier<CheckInState> {
  final CheckInRepository _repository;

  CheckInNotifier(this._repository) : super(const CheckInInitial());

  Future<void> performCheckIn({
    double? latitude,
    double? longitude,
    String method = 'button',
    String? notes,
  }) async {
    try {
      state = const CheckInLoading();

      final checkIn = await _repository.performCheckIn(
        latitude: latitude,
        longitude: longitude,
        method: method,
        notes: notes,
      );

      if (!mounted) return;
      state = CheckInSuccess(checkIn);

      // Reset to initial after a delay
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      state = const CheckInInitial();
    } catch (e) {
      if (!mounted) return;
      state = CheckInError(e.toString());
    }
  }
}

// ==================== Check-In Status Notifier ====================

class CheckInStatusNotifier extends StateNotifier<CheckInStatusData> {
  final CheckInRepository _repository;
  Timer? _refreshTimer;

  CheckInStatusNotifier(this._repository)
      : super(const CheckInStatusData(isLoading: true)) {
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    try {
      if (!mounted) return;

      final token = await TokenStorageService.getToken();
      if (token == null || token.isEmpty) return;

      state = state.copyWith(isLoading: true);
      final status =
          await _repository.fetchStatus().timeout(const Duration(seconds: 8));

      if (!mounted) return;

      DateTime? lastCheckIn;
      if (status['lastCheckIn'] != null) {
        if (status['lastCheckIn'] is Map) {
          // Backend returns lastCheckIn as an object with timestamp
          lastCheckIn = DateTime.tryParse(
              status['lastCheckIn']['timestamp']?.toString() ?? '');
        } else {
          lastCheckIn = DateTime.tryParse(status['lastCheckIn'].toString());
        }
      }

      DateTime? nextCheckInTime;
      // Always use 24h from last check-in (check-in window is always 24h)
      if (lastCheckIn != null) {
        nextCheckInTime = lastCheckIn.add(const Duration(hours: 24));
      }

      final canCheckIn =
          nextCheckInTime == null || DateTime.now().isAfter(nextCheckInTime);

      Future.microtask(() {
        if (!mounted) return;
        state = CheckInStatusData(
          lastCheckIn: lastCheckIn,
          hoursSinceLastCheckIn: status['hoursSinceLastCheckIn'] as int?,
          needsCheckIn: canCheckIn,
          canCheckIn: canCheckIn,
          nextCheckInTime: nextCheckInTime,
          streak: status['streak'] as int? ?? 0,
          isAtRisk: status['isAtRisk'] as bool? ?? false,
          isLoading: false,
        );
      });
    } catch (e) {
      debugPrint('Error fetching check-in status: $e');
      if (!mounted) return;
      // Offline / timeout fallback — read last check-in from local SharedPrefs
      // so the button shows the correct state without waiting for the server.
      _applyLocalFallback();
    }
  }

  /// Applies a local fallback state using SharedPrefs when the server is unreachable.
  void _applyLocalFallback() {
    if (!mounted) return;
    try {
      final lastCheckIn = SharedPrefsService().lastCheckIn;
      if (lastCheckIn != null) {
        final nextCheckInTime = lastCheckIn.add(const Duration(hours: 24));
        final canCheckIn = DateTime.now().isAfter(nextCheckInTime);
        final hoursSince = DateTime.now().difference(lastCheckIn).inHours;

        if (!mounted) return;
        state = CheckInStatusData(
          lastCheckIn: lastCheckIn,
          hoursSinceLastCheckIn: hoursSince,
          needsCheckIn: canCheckIn,
          canCheckIn: canCheckIn,
          nextCheckInTime: nextCheckInTime,
          streak: state.streak,
          isAtRisk: false,
          isLoading: false,
        );
      } else {
        // No local data — assume user needs to check in
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          canCheckIn: true,
          needsCheckIn: true,
        );
      }
    } catch (e) {
      debugPrint('CheckInStatusNotifier: Fallback error: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  /// Called after a successful check-in to refresh status
  Future<void> onCheckInComplete() async {
    try {
      if (!mounted) return;
      state = state.copyWith(isLoading: true);

      final stats = await _repository.fetchStatus();

      if (!mounted) return;

      state = state.copyWith(
        lastCheckIn: DateTime.now(),
        needsCheckIn: false,
        canCheckIn: false,
        nextCheckInTime: DateTime.now().add(const Duration(hours: 24)),
        streak: stats['streak'] as int? ?? (state.streak + 1),
        isAtRisk: false,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error updating check-in state: $e');
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class CheckInHistoryNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final CheckInRepository _repository;

  CheckInHistoryNotifier(this._repository) : super(const AsyncLoading()) {
    _bootstrap();
  }

  Future<void>? _fetchInFlight;

  Future<void> _bootstrap() async {
    final cachedHistory = await _repository.getCachedHistory();
    final localHistory = _repository
        .getAllCheckIns()
        .map((item) => _repository.checkinModelToApiMap(item))
        .toList();
    final merged = _repository.mergeHistory(cachedHistory, localHistory);
    if (!mounted) return;
    if (merged.isNotEmpty) {
      state = AsyncData(merged);
    }
    await fetch(silent: merged.isNotEmpty);
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
      final history = await _repository.fetchHistory(limit: 100, skip: 0);
      if (!mounted) return;
      state = AsyncData(history);
    } catch (e, st) {
      if (!mounted) return;
      if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }
}

// ==================== Providers ====================

final checkinProvider =
    StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  return CheckInNotifier(ref.watch(checkinRepositoryProvider));
});

final checkinStatusProvider =
    StateNotifierProvider<CheckInStatusNotifier, CheckInStatusData>((ref) {
  return CheckInStatusNotifier(ref.watch(checkinRepositoryProvider));
});

// Provider for check-in history (local Hive fallback)
final checkinHistoryProvider = Provider<List<CheckInModel>>((ref) {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getAllCheckIns();
});

// Provider for check-in history with persistent cached-first loading
final checkinHistoryFromBackendProvider = StateNotifierProvider<
    CheckInHistoryNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CheckInHistoryNotifier(ref.watch(checkinRepositoryProvider));
});

// Provider for user stats from backend
final userStatsFromBackendProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final authApi = AuthApiService();
    final profileData = await authApi.getProfile();
    final user = profileData['user'] as Map<String, dynamic>? ?? {};
    return {
      'totalCheckIns': user['checkInStreak'] ?? 0,
      'streak': user['checkInStreak'] ?? 0,
    };
  } catch (e) {
    debugPrint('Failed to fetch user stats: $e');
    return {'totalCheckIns': 0, 'streak': 0};
  }
});

// Provider for last check-in
final lastCheckinProvider = Provider<CheckInModel?>((ref) {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getLastCheckIn();
});

// Provider for time until next check-in
final hoursUntilNextCheckinProvider = Provider<int?>((ref) {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getHoursUntilNextCheckIn();
});
