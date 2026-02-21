import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/contact_provider.dart';
import '../../../model/emergency_contact_model.dart';
import '../../../services/location_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/api/emergency_api_service.dart';

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnim;
  
  bool _isActivating = false;
  bool _isActivated = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  Position? _currentPosition;
  StreamSubscription<Position>? _locationSubscription;
  String? _activeAlertId;
  final _emergencyApi = EmergencyApiService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _countdownTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _startSOS() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isActivating = true;
      _countdown = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });
      HapticFeedback.lightImpact();

      if (_countdown <= 0) {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _cancelSOS() {
    _countdownTimer?.cancel();
    _locationSubscription?.cancel();
    setState(() {
      _isActivating = false;
      _isActivated = false; // Also reset activated state if needed? 
      // User might want to stop active SOS. 
      // The button "I am Safe" does separate logic.
      _countdown = 5;
    });
  }

  Future<void> _triggerSOS() async {
    setState(() {
      _isActivated = true;
      _isActivating = false;
    });

    HapticFeedback.heavyImpact();

    // Get location
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Continue without location
    }

    // Get real contacts
    final contacts = ref.read(contactListProvider);
    
    // Start sharing location via Socket
    final locationService = ref.read(locationServiceProvider);
    final socketService = ref.read(socketServiceProvider);
    
    // Initial location emission
    if (_currentPosition != null) {
      socketService.emitLocationUpdate(
        _currentPosition!.latitude, 
        _currentPosition!.longitude
      );
    }
    
    // Stream updates
    _locationSubscription?.cancel();
    _locationSubscription = locationService.getLocationStream().listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
      socketService.emitLocationUpdate(position.latitude, position.longitude);
    });

    // === Call backend SOS endpoint to send SMS+Email alerts ===
    try {
      final result = await _emergencyApi.triggerSOS(
        latitude: _currentPosition?.latitude ?? 23.8103,
        longitude: _currentPosition?.longitude ?? 90.4125,
      );
      _activeAlertId = result['alert']?['_id']?.toString();
      
      if (mounted) {
        final notifiedCount = result['contactsNotified'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SOS সক্রিয়! $notifiedCount জন যোগাযোগকারীকে সতর্ক করা হয়েছে',
              style: TextStyle(fontFamily: 'HindSiliguri'),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Backend SOS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'জরুরি সতর্কতা পাঠানো হচ্ছে (অফলাইন মোড)',
              style: TextStyle(fontFamily: 'HindSiliguri'),
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _isActivated
          ? const Color(0xFFD32F2F)
          : (isDark ? AppColors.backgroundDark : AppColors.background),
      appBar: AppBar(
        title: const Text('জরুরি SOS'),
        backgroundColor: Colors.transparent,
        foregroundColor: _isActivated ? Colors.white : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isActivating
                    ? _buildCountdownView()
                    : _isActivated
                        ? _buildActivatedView()
                        : _buildSOSButton(),
              ),
            ),

            // Emergency contacts
            if (!_isActivating && !_isActivated) ...[
              _buildContactsSection(contacts, isDark),
              const SizedBox(height: 16),
              // Emergency Numbers
              _buildEmergencyNumbers(isDark),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'জরুরি সাহায্যের জন্য\nদীর্ঘক্ষণ চাপুন',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontFamily: 'HindSiliguri',
          ),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            );
          },
          child: GestureDetector(
            onLongPress: _startSOS,
            child: Hero(
              tag: 'sos_icon',
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF44336).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFFF44336).withOpacity(0.2),
                      blurRadius: 60,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sos, color: Colors.white, size: 56),
                    const SizedBox(height: 8),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'HindSiliguri',
                        letterSpacing: 4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SOS সক্রিয় হচ্ছে...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'HindSiliguri',
          ),
        ),
        const SizedBox(height: 40),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withOpacity(0.1),
            border: Border.all(color: AppColors.error, width: 4),
          ),
          child: Center(
            child: Text(
              '$_countdown',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                fontFamily: 'HindSiliguri',
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: _cancelSOS,
          icon: const Icon(Icons.close, color: AppColors.error),
          label: const Text(
            'বাতিল করুন',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'HindSiliguri',
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivatedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 80,
        ),
        const SizedBox(height: 20),
        Text(
          'SOS সক্রিয় হয়েছে!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'HindSiliguri',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'আপনার জরুরি যোগাযোগকারীদের\nসতর্কতা পাঠানো হয়েছে',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'HindSiliguri',
          ),
        ),
        if (_currentPosition != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'লোকেশন শেয়ার করা হয়েছে',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'HindSiliguri',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () async {
            // Resolve alert on backend
            if (_activeAlertId != null) {
              try {
                await _emergencyApi.resolveAlert(_activeAlertId!);
              } catch (e) {
                debugPrint('Failed to resolve alert: $e');
              }
            }
            setState(() {
              _isActivated = false;
              _locationSubscription?.cancel();
              _activeAlertId = null;
            });
          },
          icon: const Icon(Icons.check),
          label: const Text(
            'আমি নিরাপদ',
            style: TextStyle(fontFamily: 'HindSiliguri'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsSection(List<EmergencyContactModel> contacts, bool isDark) {
    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardDecoration(context: context),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'জরুরি যোগাযোগ যোগ করুন',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'জরুরি যোগাযোগ (${contacts.length})',
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...contacts.take(3).map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: AppDecorations.cardDecoration(context: context),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'HindSiliguri',
                            ),
                          ),
                          Text(
                            c.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumbers(bool isDark) {
    final numbers = [
      {'name': '৯৯৯ (জাতীয় জরুরি)', 'number': '999'},
      {'name': 'ফায়ার সার্ভিস', 'number': '199'},
      {'name': 'অ্যাম্বুলেন্স', 'number': '199'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'জরুরি নম্বর',
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: numbers.map((n) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: AppDecorations.cardDecoration(context: context),
                child: Column(
                  children: [
                    Text(
                      n['number']!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['name']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'HindSiliguri',
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
