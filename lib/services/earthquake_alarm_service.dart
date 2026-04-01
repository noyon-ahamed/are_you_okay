import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class EarthquakeAlarmService {
  EarthquakeAlarmService._internal();

  static final EarthquakeAlarmService _instance =
      EarthquakeAlarmService._internal();

  factory EarthquakeAlarmService() => _instance;

  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();

  static const Duration _autoStopAfter = Duration(seconds: 20);

  String? _activeEventId;
  Timer? _autoStopTimer;

  Future<void> startCloseAlert({required String eventId}) async {
    if (eventId.isEmpty) return;
    if (_activeEventId == eventId) return;

    await stop();

    try {
      await _player.playAlarm(
        looping: !Platform.isIOS,
        asAlarm: true,
        volume: 1.0,
      );
      _activeEventId = eventId;
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(_autoStopAfter, () {
        unawaited(stop());
      });
    } catch (error) {
      debugPrint('Earthquake alarm start failed: $error');
    }
  }

  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _activeEventId = null;

    try {
      await _player.stop();
    } catch (error) {
      debugPrint('Earthquake alarm stop failed: $error');
    }
  }
}
