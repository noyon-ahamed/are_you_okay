import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

final voiceDetectorServiceProvider = Provider<VoiceDetectorService>((ref) {
  return VoiceDetectorService();
});

class VoiceDetectorService {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  
  // Configuration
  double _threshold = 95.0; // dB
  bool _isEnabled = false;
  
  // Callbacks
  Function()? onScreamDetected;

  VoiceDetectorService() {
    _noiseMeter = NoiseMeter();
  }

  void updateThreshold(double threshold) {
    _threshold = threshold;
  }

  Future<void> startListening() async {
    if (_isEnabled) return;
    
    // Check permission
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      debugPrint('Microphone permission not granted for Voice SOS');
      return;
    }

    try {
      _noiseSubscription = _noiseMeter?.noise.listen(
        (NoiseReading noiseReading) {
          _onData(noiseReading);
        },
        onError: (Object error) {
          debugPrint('NoiseMeter error: $error');
          stopListening();
        },
        cancelOnError: true,
      );
      _isEnabled = true;
      debugPrint('VoiceDetectorService started');
    } catch (e) {
      debugPrint('Error starting NoiseMeter: $e');
    }
  }

  void _onData(NoiseReading noiseReading) {
    // noiseReading.meanDecibel or noiseReading.maxDecibel
    if (noiseReading.maxDecibel >= _threshold) {
      debugPrint('Loud sound detected: ${noiseReading.maxDecibel} dB');
      onScreamDetected?.call();
    }
  }

  void stopListening() {
    _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _isEnabled = false;
    debugPrint('VoiceDetectorService stopped');
  }

  bool get isEnabled => _isEnabled;
}
