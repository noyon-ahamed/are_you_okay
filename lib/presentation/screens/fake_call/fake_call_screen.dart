import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  // Call state
  _CallState _callState = _CallState.setup;

  // Caller presets
  int _selectedPreset = 0;
  final List<_CallerPreset> _presets = [
    _CallerPreset(name: 'বন্ধু', number: '+880 1611-564875', icon: Icons.group, color: Color(0xFF4CAF50)),
    _CallerPreset(name: 'মা', number: '+880 1711-564875', icon: Icons.favorite, color: Color(0xFFE91E63)),
    _CallerPreset(name: 'বাবা', number: '+880 1811-564875', icon: Icons.person, color: Color(0xFF2196F3)),
    _CallerPreset(name: 'বস', number: '+880 1911-564875', icon: Icons.work, color: Color(0xFF795548)),
    _CallerPreset(name: 'পুলিশ', number: '৯৯৯', icon: Icons.local_police, color: Color(0xFF607D8B)),
  ];

  // Custom name controller
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  // Timer
  Timer? _delayTimer;
  int _delaySeconds = 5;
  int _remainingDelay = 0;

  // CallKit details
  final Uuid _uuid = const Uuid();
  String? _currentCallId;
  StreamSubscription<CallEvent?>? _callkitEventSubscription;

  @override
  void initState() {
    super.initState();
    _nameController.text = _presets[_selectedPreset].name;
    _numberController.text = _presets[_selectedPreset].number;
    _listenToCallKitEvents();
  }

  void _listenToCallKitEvents() {
    _callkitEventSubscription =
        FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          // Global listener in main.dart handles navigation
          setState(() => _callState = _CallState.setup);
          WakelockPlus.disable();
          break;
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          debugPrint('Call ended or declined natively');
          setState(() => _callState = _CallState.setup);
          WakelockPlus.disable();
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _nameController.dispose();
    _numberController.dispose();
    _callkitEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startFakeCall() async {
    // Request notification permissions for CallKit (Required for Android 13+)
    await FlutterCallkitIncoming.requestNotificationPermission({
      "rationaleMessagePermission": "Notification permission is required to show the call screen.",
      "postNotificationMessageRequired": "Please allow notification permission from settings to receive fake calls."
    });

    if (!mounted) return;

    setState(() {
      _callState = _CallState.waiting;
      _remainingDelay = _delaySeconds;
    });

    // Ensure the screen wakes up in case the phone is locked when the timer hits
    WakelockPlus.enable();

    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingDelay--;
      });

      if (_remainingDelay <= 0) {
        timer.cancel();
        _showIncomingCall();
      }
    });
  }

  Future<void> _showIncomingCall() async {
    _currentCallId = _uuid.v4();

    // Append the number to the name to force Android to display the number
    // beneath the caller's name in the native notification view.
    final String compoundName = "$_currentCallerName\n$_currentCallerNumber";

    final params = CallKitParams(
      id: _currentCallId,
      nameCaller: compoundName,
      appName: 'Are You Okay',
      avatar: '', 
      handle: _currentCallerNumber,
      type: 0, 
      duration: 30000, 
      textAccept: 'গ্রহণ',
      textDecline: 'হটান',
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'মিসড কল',
        callbackText: 'কল ব্যাক',
      ),
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
      ),
      ios: IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    
    // Pop the fake call setup screen, as CallKit is now handling the foreground overlay
    if (mounted) {
      context.pop();
    }
  }

  void _cancelTimer() {
    _delayTimer?.cancel();
    WakelockPlus.disable();
    setState(() {
      _callState = _CallState.setup;
    });
  }

  String get _currentCallerName {
    if (_nameController.text.isNotEmpty) return _nameController.text;
    return _presets[_selectedPreset].name;
  }

  String get _currentCallerNumber {
    if (_numberController.text.isNotEmpty) return _numberController.text;
    return _presets[_selectedPreset].number;
  }

  @override
  Widget build(BuildContext context) {
    if (_callState == _CallState.waiting) {
       return _buildWaitingScreen();
    }
    return _buildSetupScreen();
  }

  // ==================== Setup Screen ====================
  Widget _buildSetupScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('ফেক কল')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preset selection
            const Text('কলার নির্বাচন',
                style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_presets.length, (i) {
                final preset = _presets[i];
                final isSelected = _selectedPreset == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPreset = i;
                        _nameController.text = _presets[i].name;
                        _numberController.text = _presets[i].number;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? preset.color.withOpacity(0.15)
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? preset.color
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(preset.icon, color: preset.color, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            preset.name,
                            style: TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? preset.color : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Custom fields
            const Text('অথবা কাস্টম',
                style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'কলারের নাম',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'কলারের নম্বর',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // Delay slider
            const Text('বিলম্ব',
                style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$_delaySeconds সেকেন্ড পরে কল আসবে',
                style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            Slider(
              value: _delaySeconds.toDouble(),
              min: 3,
              max: 60,
              divisions: 57,
              activeColor: AppColors.primary,
              label: '$_delaySeconds সেকেন্ড',
              onChanged: (val) =>
                  setState(() => _delaySeconds = val.round()),
            ),

            const SizedBox(height: 32),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startFakeCall,
                icon: const Icon(Icons.phone),
                label: const Text('ফেক কল শুরু',
                    style: TextStyle(fontFamily: 'HindSiliguri')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Waiting Screen ====================
  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_callback, color: Colors.white54, size: 48),
              const SizedBox(height: 24),
              Text(
                '$_remainingDelay',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: 'HindSiliguri',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'সেকেন্ড পরে কল আসবে...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                  fontFamily: 'HindSiliguri',
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _cancelTimer,
                child: const Text('বাতিল',
                    style: TextStyle(
                        color: Colors.white54, fontFamily: 'HindSiliguri')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Models ====================
enum _CallState { setup, waiting }

class _CallerPreset {
  final String name;
  final String number;
  final IconData icon;
  final Color color;

  const _CallerPreset({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
  });
}
