import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../../main.dart';

class FakeCallActiveScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;
  final String callId;

  const FakeCallActiveScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    required this.callId,
  });

  @override
  State<FakeCallActiveScreen> createState() => _FakeCallActiveScreenState();
}

class _FakeCallActiveScreenState extends State<FakeCallActiveScreen> {
  Timer? _durationTimer;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration++);
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _endFakeCall() async {
    await FlutterCallkitIncoming.endCall(widget.callId);
    globalActiveCallNotifier.value = null;
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    String seconds = (_callDuration % 60).toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E), // Dark professional background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Caller Info
            const Icon(Icons.account_circle, size: 100, color: Colors.white54),
            const SizedBox(height: 24),
            Text(
              widget.callerName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                fontFamily: 'HindSiliguri',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.callerNumber,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
                fontFamily: 'HindSiliguri',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Text(
              "$minutes:$seconds",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            // Actions
            Padding(
              padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  GestureDetector(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isMuted ? Colors.white : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.black : Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Speaker
                  GestureDetector(
                    onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isSpeaker ? Colors.white : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSpeaker ? Icons.volume_up : Icons.volume_down,
                        color: _isSpeaker ? Colors.black : Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // End Call
                  GestureDetector(
                    onTap: _endFakeCall,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
