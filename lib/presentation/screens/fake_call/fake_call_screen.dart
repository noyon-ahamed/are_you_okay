import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with TickerProviderStateMixin {
  // Call state
  _CallState _callState = _CallState.setup;

  // Caller presets
  int _selectedPreset = 0;
  final List<_CallerPreset> _presets = [
    _CallerPreset(name: 'মা', number: '+880 1711-XXXXXX', icon: Icons.favorite, color: Color(0xFFE91E63)),
    _CallerPreset(name: 'বাবা', number: '+880 1811-XXXXXX', icon: Icons.person, color: Color(0xFF2196F3)),
    _CallerPreset(name: 'বস', number: '+880 1911-XXXXXX', icon: Icons.work, color: Color(0xFF795548)),
    _CallerPreset(name: 'পুলিশ', number: '৯৯৯', icon: Icons.local_police, color: Color(0xFF607D8B)),
  ];

  // Custom name controller
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  // Timer
  Timer? _delayTimer;
  Timer? _callTimer;
  int _delaySeconds = 5;
  int _callDuration = 0;
  int _remainingDelay = 0;

  // Animation
  late AnimationController _ringAnimController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ringAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _ringAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _callTimer?.cancel();
    _ringAnimController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _startFakeCall() {
    setState(() {
      _callState = _CallState.waiting;
      _remainingDelay = _delaySeconds;
    });

    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingDelay--;
      });

      if (_remainingDelay <= 0) {
        timer.cancel();
        _showIncomingCall();
      }
    });
  }

  void _showIncomingCall() {
    HapticFeedback.heavyImpact();
    _ringAnimController.repeat(reverse: true);

    setState(() {
      _callState = _CallState.incoming;
    });
  }

  void _acceptCall() {
    _ringAnimController.stop();
    _ringAnimController.reset();
    HapticFeedback.mediumImpact();

    setState(() {
      _callState = _CallState.talking;
      _callDuration = 0;
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    _delayTimer?.cancel();
    _ringAnimController.stop();
    _ringAnimController.reset();

    setState(() {
      _callState = _CallState.setup;
      _callDuration = 0;
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

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    switch (_callState) {
      case _CallState.setup:
        return _buildSetupScreen();
      case _CallState.waiting:
        return _buildWaitingScreen();
      case _CallState.incoming:
        return _buildIncomingScreen();
      case _CallState.talking:
        return _buildTalkingScreen();
    }
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
            Text('কলার নির্বাচন',
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
                      setState(() => _selectedPreset = i);
                      _nameController.clear();
                      _numberController.clear();
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
            Text('অথবা কাস্টম',
                style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'কলারের নাম',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'কলারের নম্বর',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // Delay slider
            Text('বিলম্ব',
                style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$_delaySeconds সেকেন্ড পরে কল আসবে',
                style: TextStyle(
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
                label: Text('ফেক কল শুরু',
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
              Icon(Icons.phone_callback, color: Colors.white54, size: 48),
              const SizedBox(height: 24),
              Text(
                '$_remainingDelay',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: 'HindSiliguri',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'সেকেন্ড পরে কল আসবে...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                  fontFamily: 'HindSiliguri',
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _endCall,
                child: Text('বাতিল',
                    style: TextStyle(
                        color: Colors.white54, fontFamily: 'HindSiliguri')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Incoming Call Screen ====================
  Widget _buildIncomingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Caller avatar
            AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _ringAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _presets[_selectedPreset].color,
                      _presets[_selectedPreset].color.withOpacity(0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _presets[_selectedPreset]
                          .color
                          .withOpacity(0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(
                  _presets[_selectedPreset].icon,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentCallerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'HindSiliguri',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ইনকামিং কল...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'HindSiliguri',
              ),
            ),
            const Spacer(flex: 3),
            // Accept/Decline buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'বাতিল',
                    onTap: _endCall,
                  ),
                  _buildCallButton(
                    icon: Icons.call,
                    color: Colors.green,
                    label: 'গ্রহণ',
                    onTap: _acceptCall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ==================== Talking Screen ====================
  Widget _buildTalkingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Caller info
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _presets[_selectedPreset].color,
                    _presets[_selectedPreset].color.withOpacity(0.6),
                  ],
                ),
              ),
              child: Icon(
                _presets[_selectedPreset].icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _currentCallerName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'HindSiliguri',
              ),
            ),
            const SizedBox(height: 8),
            // Real-time duration
            Text(
              _formatDuration(_callDuration),
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'HindSiliguri',
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            // Action buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSmallButton(Icons.mic_off, 'মিউট'),
                  _buildSmallButton(Icons.volume_up, 'স্পিকার'),
                  _buildSmallButton(Icons.dialpad, 'কীপ্যাড'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // End call
            _buildCallButton(
              icon: Icons.call_end,
              color: Colors.red,
              label: 'কল শেষ',
              onTap: _endCall,
              size: 72,
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    double size = 64,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }

  Widget _buildSmallButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }
}

// ==================== Models ====================
enum _CallState { setup, waiting, incoming, talking }

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
