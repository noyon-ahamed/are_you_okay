import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Provider for ShakeDetectorService
final shakeDetectorProvider = Provider<ShakeDetectorService>((ref) {
  return ShakeDetectorService();
});

/// Service to detect phone shakes using accelerometer
class ShakeDetectorService {
  // Configuration
  final double _shakeThresholdGravity = 2.7;
  final int _minTimeBetweenShakesMs = 500;
  final int _shakeCountResetTimeMs = 3000;
  final int _minShakesToTrigger = 3;

  // State
  int _shakeCount = 0;
  int _lastShakeTimestamp = 0;
  StreamSubscription? _accelerometerSubscription;
  Function()? _onPhoneShake;

  ShakeDetectorService();

  /// Start listening for shakes
  void startListening(Function() onPhoneShake) {
    _onPhoneShake = onPhoneShake;
    if (_accelerometerSubscription != null) return;

    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      final double gX = event.x / 9.8;
      final double gY = event.y / 9.8;
      final double gZ = event.z / 9.8;

      // gForce will be close to 1 when there is no movement
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > _shakeThresholdGravity) {
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Ignore shakes that are too close together
        if (_lastShakeTimestamp + _minTimeBetweenShakesMs > now) {
          return;
        }

        // Reset shake count if too much time has passed
        if (_lastShakeTimestamp + _shakeCountResetTimeMs < now) {
          _shakeCount = 0;
        }

        _lastShakeTimestamp = now;
        _shakeCount++;

        if (_shakeCount >= _minShakesToTrigger) {
          _onPhoneShake?.call();
          _shakeCount = 0; // Reset after trigger
        }
      }
    });
  }

  /// Stop listening
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _shakeCount = 0;
  }
}
