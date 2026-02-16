import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../../../core/theme/app_colors.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  Timer? _timer;
  bool _isIncoming = false;
  bool _isTalking = false;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  int _secondsRemaining = 0;
  
  // Settings
  String _callerName = 'Police';
  String _callerNumber = '999';
  int _delaySeconds = 5;

  @override
  void dispose() {
    _timer?.cancel();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  void _scheduleCall() {
    setState(() {
      _secondsRemaining = _delaySeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _triggerIncomingCall();
      }
    });
  }

  void _triggerIncomingCall() async {
    setState(() {
      _isIncoming = true;
    });
    
    // Play ringtone and vibrate
    await _ringtonePlayer.play(AssetSource('sounds/ringtone.mp3')); // Make sure this asset exists
    // Fallback vibration if ringtone plays or loops
    if (await Vibrate.canVibrate) {
      Vibrate.vibrate(); // Vibrate for 1s, repeat in loop logic if needed
      Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (!_isIncoming) {
          timer.cancel();
        } else {
          Vibrate.vibrate();
        }
      });
    }
  }

  void _acceptCall() {
    _ringtonePlayer.stop();
    setState(() {
      _isIncoming = false;
      _isTalking = true;
    });
    // Start duration timer logic here if needed
  }

  void _endCall() {
    _ringtonePlayer.stop();
    if (_isTalking || _isIncoming) {
      setState(() {
        _isIncoming = false;
        _isTalking = false;
        _secondsRemaining = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isIncoming) {
      return _buildIncomingCallUI();
    }
    if (_isTalking) {
      return _buildTalkingUI();
    }
    return _buildSettingsUI();
  }

  Widget _buildSettingsUI() {
    return Scaffold(
      appBar: AppBar(title: const Text('ফেইক কল সেটআপ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'কলারের নাম'),
              onChanged: (val) => _callerName = val,
              controller: TextEditingController(text: _callerName),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'নাম্বার'),
              onChanged: (val) => _callerNumber = val,
              controller: TextEditingController(text: _callerNumber),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _delaySeconds,
              decoration: const InputDecoration(labelText: 'সময় (সেকেন্ড)'),
              items: [5, 10, 30, 60].map((e) => DropdownMenuItem(value: e, child: Text('$e সেকেন্ড'))).toList(),
              onChanged: (val) => setState(() => _delaySeconds = val!),
            ),
            const Spacer(),
            if (_secondsRemaining > 0)
              Text(
                'কল আসছে $_secondsRemaining সেকেন্ডে...',
                style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _secondsRemaining > 0 ? null : _scheduleCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('কল শিডিউল করুণ', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingCallUI() {
    return Scaffold(
      backgroundColor: Colors.black, // Typical incoming call background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              _callerName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _callerNumber,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 64, left: 32, right: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      FloatingActionButton(
                        onPressed: _endCall,
                        backgroundColor: Colors.red,
                        heroTag: 'decline',
                        child: const Icon(Icons.call_end),
                      ),
                      const SizedBox(height: 8),
                      const Text('প্রত্যাখ্যান', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      FloatingActionButton(
                        onPressed: _acceptCall,
                        backgroundColor: Colors.green,
                        heroTag: 'accept',
                        child: const Icon(Icons.call),
                      ),
                      const SizedBox(height: 8),
                      const Text('রিসিভ', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalkingUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _callerName,
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '00:05', // Static timer for simplicity
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: FloatingActionButton(
                onPressed: _endCall,
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
