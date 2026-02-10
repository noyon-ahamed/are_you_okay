import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/checkin_model.dart';
import '../repository/checkin_repository.dart';

// CheckIn State
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

// CheckIn Notifier
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