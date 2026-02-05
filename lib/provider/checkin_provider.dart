import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../model/checkin_model.dart';
import '../repository/checkin_repository.dart';

part 'checkin_provider.freezed.dart';

// CheckIn State
@freezed
class CheckInState with _$CheckInState {
  const factory CheckInState.initial() = _Initial;
  const factory CheckInState.loading() = _Loading;
  const factory CheckInState.success(CheckInModel checkIn) = _Success;
  const factory CheckInState.error(String message) = _Error;
}

// CheckIn Notifier
class CheckInNotifier extends StateNotifier<CheckInState> {
  final CheckInRepository _repository;

  CheckInNotifier(this._repository) : super(const CheckInState.initial());

  Future<void> performCheckIn({
    double? latitude,
    double? longitude,
    String method = 'button',
    String? notes,
  }) async {
    try {
      state = const CheckInState.loading();
      
      final checkIn = await _repository.performCheckIn(
        latitude: latitude,
        longitude: longitude,
        method: method,
        notes: notes,
      );
      
      state = CheckInState.success(checkIn);
      
      // Reset to initial after a delay
      await Future.delayed(const Duration(seconds: 2));
      state = const CheckInState.initial();
    } catch (e) {
      state = CheckInState.error(e.toString());
    }
  }

  CheckInModel? getLastCheckIn() {
    return _repository.getLastCheckIn();
  }

  int? getHoursUntilNextCheckIn() {
    return _repository.getHoursUntilNextCheckIn();
  }

  int? getMinutesUntilNextCheckIn() {
    return _repository.getMinutesUntilNextCheckIn();
  }

  bool isCheckInOverdue() {
    return _repository.isCheckInOverdue();
  }
}

// Providers
final checkinProvider =
    StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  return CheckInNotifier(ref.watch(checkinRepositoryProvider));
});

// Provider for check-in history
final checkinHistoryProvider = Provider<List<CheckInModel>>((ref) {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getAllCheckIns();
});

// Provider for recent check-ins
final recentCheckinsProvider = Provider.family<List<CheckInModel>, int>(
  (ref, limit) {
    final repository = ref.watch(checkinRepositoryProvider);
    return repository.getRecentCheckIns(limit: limit);
  },
);

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

// Provider for check-in stats
final checkinStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(checkinRepositoryProvider);
  return repository.getCheckInStats();
});