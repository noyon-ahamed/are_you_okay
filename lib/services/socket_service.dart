import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/app_constants.dart';
import 'shared_prefs_service.dart';

/// Provider for SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

/// Service to handle real-time communication via Socket.IO
class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Stream controllers for events
  final _checkInStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyStreamController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get checkInStream => _checkInStreamController.stream;
  Stream<Map<String, dynamic>> get emergencyStream => _emergencyStreamController.stream;
  bool get isConnected => _isConnected;

  SocketService();

  /// Initialize socket connection
  Future<void> init() async {
    if (_socket != null && _socket!.connected) return;

    final token = await SharedPrefsService.getToken();
    if (token == null) return;

    // Configure socket
    _socket = IO.io(
      AppConstants.apiBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    // Connect
    _socket!.connect();

    // Listeners
    _socket!.onConnect((_) {
      _isConnected = true;
      print('Socket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('Socket disconnected');
    });

    _socket!.onError((data) {
      print('Socket error: $data');
    });

    // Custom Events
    _socket!.on('checkin_update', (data) {
      if (data is Map<String, dynamic>) {
        _checkInStreamController.add(data);
      }
    });

    _socket!.on('emergency_alert', (data) {
      if (data is Map<String, dynamic>) {
        _emergencyStreamController.add(data);
      }
    });
  }

  /// Emit check-in event
  void emitCheckIn(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit('checkin', data);
    }
  }

  /// Emit emergency triggering
  void emitEmergency(Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit('emergency_trigger', data);
    }
  }

  /// Emit location update during SOS
  void emitLocationUpdate(double latitude, double longitude) {
    if (_socket != null && _isConnected) {
      _socket!.emit('location_update', {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }

  /// Dispose
  void dispose() {
    disconnect();
    _checkInStreamController.close();
    _emergencyStreamController.close();
  }
}
