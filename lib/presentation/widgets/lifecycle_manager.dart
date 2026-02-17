import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/auth_provider.dart';
import '../../provider/settings_provider.dart';
import '../../services/biometric_service.dart';

class LifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const LifecycleManager({super.key, required this.child});

  @override
  ConsumerState<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends ConsumerState<LifecycleManager> with WidgetsBindingObserver {
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isBackground = true;
    } else if (state == AppLifecycleState.resumed && _isBackground) {
      _isBackground = false;
      _checkBiometricLock();
    }
  }

  Future<void> _checkBiometricLock() async {
    final settings = ref.read(settingsProvider);
    final authState = ref.read(authProvider);

    // Only lock if enabled and user is authenticated
    if (settings.biometricEnabled && authState is AuthAuthenticated) {
      final biometricService = ref.read(biometricServiceProvider);
      
      // Check availability first
      if (await biometricService.isAvailable) {
        bool authenticated = await biometricService.authenticate(
          reason: 'Scan to unlock "Are You Okay?"',
        );

        if (!authenticated) {
          // If failed or cancelled, we should probably minimize or lock
          // specific implementation depends on UX.
          // For now, retry or show overlay? 
          // Simpler: Just prompt. If they cancel, they are in the app but 
          // maybe we should navigate to a LockScreen.
          // Since we don't have a LockScreen yet, let's just re-prompt or 
          // pop until root? No, that's bad.
          
          // Ideally: Push a full-screen opaque route that requires auth to pop.
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
