import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../provider/language_provider.dart';
import '../../../core/localization/app_strings.dart';

class FakeCallScreen extends ConsumerStatefulWidget {
  const FakeCallScreen({super.key});

  @override
  ConsumerState<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends ConsumerState<FakeCallScreen>
    with RestorationMixin {
  // Call state
  _CallState _callState = _CallState.setup;

  // Caller presets
  final RestorableInt _selectedPresetState = RestorableInt(0);
  final RestorableInt _delaySecondsState = RestorableInt(5);
  final RestorableTextEditingController _nameController =
      RestorableTextEditingController();
  final RestorableTextEditingController _numberController =
      RestorableTextEditingController();
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;
  int _selectedPreset = 0;
  List<_CallerPreset> _getPresets(AppStrings s) => [
        _CallerPreset(
            name: s.fcCallerFriend,
            number: '+880 1611-564875',
            icon: Icons.group,
            color: const Color(0xFF4CAF50)),
        _CallerPreset(
            name: s.fcCallerMom,
            number: '+880 1711-564875',
            icon: Icons.favorite,
            color: const Color(0xFFE91E63)),
        _CallerPreset(
            name: s.fcCallerDad,
            number: '+880 1811-564875',
            icon: Icons.person,
            color: const Color(0xFF2196F3)),
        _CallerPreset(
            name: s.fcCallerBoss,
            number: '+880 1911-564875',
            icon: Icons.work,
            color: const Color(0xFF795548)),
        _CallerPreset(
            name: s.fcCallerPolice,
            number: '999',
            icon: Icons.local_police,
            color: const Color(0xFF607D8B)),
      ];

  // Timer
  Timer? _delayTimer;
  int _delaySeconds = 5;
  int _remainingDelay = 0;

  // CallKit details
  final Uuid _uuid = const Uuid();
  String? _currentCallId;
  StreamSubscription<CallEvent?>? _callkitEventSubscription;

  @override
  String? get restorationId => 'fake_call_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
    _listenToCallKitEvents();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedPresetState, 'selected_preset');
    registerForRestoration(_delaySecondsState, 'delay_seconds');
    registerForRestoration(_nameController, 'caller_name');
    registerForRestoration(_numberController, 'caller_number');
    registerForRestoration(_scrollOffset, 'scroll_offset');
    
    if (initialRestore) {
      final s = ref.read(stringsProvider);
      final presets = _getPresets(s);
      _selectedPreset = _selectedPresetState.value;
      _delaySeconds = _delaySecondsState.value;
      if (_nameController.value.text.isEmpty) {
        _nameController.value.text = presets[_selectedPreset].name;
      }
      if (_numberController.value.text.isEmpty) {
        _numberController.value.text = presets[_selectedPreset].number;
      }
    } else {
      _selectedPreset = _selectedPresetState.value;
      _delaySeconds = _delaySecondsState.value;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
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
    _selectedPresetState.dispose();
    _delaySecondsState.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
    _callkitEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startFakeCall() async {
    // Request notification permissions for CallKit (Required for Android 13+)
    final s = ref.read(stringsProvider);
    await FlutterCallkitIncoming.requestNotificationPermission({
      "rationaleMessagePermission": s.fcNotificationPermissionRationale,
      "postNotificationMessageRequired": s.fcNotificationPermissionSettings,
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
    final s = ref.read(stringsProvider);

    // Append the number to the name to force Android to display the number
    // beneath the caller's name in the native notification view.
    final String compoundName =
        "${_currentCallerName(s)}\n${_currentCallerNumber(s)}";

    final params = CallKitParams(
      id: _currentCallId,
      nameCaller: compoundName,
      appName: 'Are You Okay',
      avatar: '',
      handle: _currentCallerNumber(s),
      type: 0,
      duration: 30000,
      textAccept: s.fcAccept,
      textDecline: s.fcDecline,
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: s.fcMissedCall,
        callbackText: s.fcCallBack,
      ),
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
      ),
      ios: const IOSParams(
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

  String _currentCallerName(AppStrings s) {
    if (_nameController.value.text.isNotEmpty) {
      return _nameController.value.text;
    }
    return _getPresets(s)[_selectedPreset].name;
  }

  String _currentCallerNumber(AppStrings s) {
    if (_numberController.value.text.isNotEmpty) {
      return _numberController.value.text;
    }
    return _getPresets(s)[_selectedPreset].number;
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
    final s = ref.watch(stringsProvider);
    final presets = _getPresets(s);

    return Scaffold(
      appBar: AppBar(title: Text(s.fcTitle)),
      body: SingleChildScrollView(
        key: const PageStorageKey('fake_call_setup_scroll'),
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preset selection
            Text(s.fcCallerSelection,
                style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(presets.length, (i) {
                final preset = presets[i];
                final isSelected = _selectedPreset == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPreset = i;
                        _selectedPresetState.value = i;
                        _nameController.value.text = presets[i].name;
                        _numberController.value.text = presets[i].number;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            // ignore: deprecated_member_use
                            ? preset.color.withOpacity(0.15)
                            : (isDark
                                // ignore: deprecated_member_use
                                ? Colors.white.withOpacity(0.05)
                                // ignore: deprecated_member_use
                                : Colors.grey.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? preset.color : Colors.transparent,
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
            Text(s.fcCustomCaller,
                style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController.value,
              decoration: InputDecoration(
                labelText: s.fcCallerName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController.value,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.fcCallerNumber,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // Delay slider
            Text(s.fcDelay,
                style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$_delaySeconds ${s.fcSecondsLater}',
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
              label: '$_delaySeconds ${s.fcSecondsLiteral}',
              onChanged: (val) => setState(() {
                _delaySeconds = val.round();
                _delaySecondsState.value = _delaySeconds;
              }),
            ),

            const SizedBox(height: 32),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startFakeCall,
                icon: const Icon(Icons.phone),
                label: Text(s.fcStartCall,
                    style: const TextStyle(fontFamily: 'HindSiliguri')),
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
    final s = ref.watch(stringsProvider);
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
              Text(
                s.fcCallIncoming,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                  fontFamily: 'HindSiliguri',
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _cancelTimer,
                child: Text(s.cancel,
                    style: const TextStyle(
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
