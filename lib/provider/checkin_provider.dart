import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/checkin_model.dart';
import '../repository/checkin_repository.dart';

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
  final int streak;
  final bool isAtRisk;
  final bool isLoading;
  final String? error;

  const CheckInStatusData({
    this.lastCheckIn,
    this.hoursSinceLastCheckIn,
    this.needsCheckIn = true,
    this.streak = 0,
    this.isAtRisk = false,
    this.isLoading = false,
    this.error,
  });

  /// Time remaining until next check-in is needed (24h cycle)
  Duration get timeRemaining {
    if (lastCheckIn == null) return Duration.zero;
    
    // Next check-in is 24 hours after last check-in
    final nextCheckInTime = lastCheckIn!.add(const Duration(hours: 24));
    final now = DateTime.now();
    
    if (now.isAfter(nextCheckInTime)) return Duration.zero;
    return nextCheckInTime.difference(now);
  }

  bool get hasCheckedInToday {
    if (lastCheckIn == null) return false;
    final now = DateTime.now();
    return lastCheckIn!.year == now.year &&
        lastCheckIn!.month == now.month &&
        lastCheckIn!.day == now.day;
  }

  CheckInStatusData copyWith({
    DateTime? lastCheckIn,
    int? hoursSinceLastCheckIn,
    bool? needsCheckIn,
    int? streak,
    bool? isAtRisk,
    bool? isLoading,
    String? error,
  }) {
    return CheckInStatusData(
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      hoursSinceLastCheckIn: hoursSinceLastCheckIn ?? this.hoursSinceLastCheckIn,
      needsCheckIn: needsCheckIn ?? this.needsCheckIn,
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

      state = CheckInSuccess(checkIn);

      // Reset to initial after a delay
      await Future.delayed(const Duration(seconds: 2));
      state = const CheckInInitial();
    } catch (e) {
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
      state = state.copyWith(isLoading: true);

      final status = await _repository.fetchStatus();

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

      state = CheckInStatusData(
        lastCheckIn: lastCheckIn,
        hoursSinceLastCheckIn: status['hoursSinceLastCheckIn'] as int?,
        needsCheckIn: status['needsCheckIn'] as bool? ?? true,
        streak: status['streak'] as int? ?? 0,
        isAtRisk: status['isAtRisk'] as bool? ?? false,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetching check-in status: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Called after a successful check-in to refresh status
  void onCheckInComplete() {
    state = CheckInStatusData(
      lastCheckIn: DateTime.now(),
      hoursSinceLastCheckIn: 0,
      needsCheckIn: false,
      streak: state.streak + 1,
      isAtRisk: false,
      isLoading: false,
    );
    // Also refresh from server after a short delay
    Future.delayed(const Duration(seconds: 1), fetchStatus);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

// Provider for check-in history
final checkinHistoryProvider = Provider<List<CheckInModel>>((ref) {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getAllCheckIns();
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