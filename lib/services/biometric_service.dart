import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../provider/settings_provider.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  /// Check if biometrics are available
  Future<bool> get isAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Authenticate user
  Future<bool> authenticate({
    String reason = 'Please authenticate to access the app',
  }) async {
    if (_isAuthenticating) return false;
    
    try {
      _isAuthenticating = true;
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      _isAuthenticating = false;
      return didAuthenticate;
    } on PlatformException catch (e) {
      _isAuthenticating = false;
      print('Authentication fail: $e');
      return false;
    }
  }

  /// Cancel authentication
  Future<void> cancelAuthentication() async {
    await _auth.stopAuthentication();
    _isAuthenticating = false;
  }
}
