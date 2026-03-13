import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/contact_provider.dart';
import '../../../model/emergency_contact_model.dart';
import '../../../services/location_service.dart';
import '../../../services/socket_service.dart';
import '../../../services/api/emergency_api_service.dart';
import '../../../provider/language_provider.dart';

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen>
    with TickerProviderStateMixin, RestorationMixin {
  final RestorableBool _needPoliceState = RestorableBool(false);
  final RestorableBool _needFireState = RestorableBool(false);
  final RestorableBool _needAmbulanceState = RestorableBool(false);
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;
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

  bool _needPolice = false;
  bool _needFire = false;
  bool _needAmbulance = false;

  @override
  String? get restorationId => 'sos_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
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
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_needPoliceState, 'need_police');
    registerForRestoration(_needFireState, 'need_fire');
    registerForRestoration(_needAmbulanceState, 'need_ambulance');
    registerForRestoration(_scrollOffset, 'scroll_offset');
    _needPolice = _needPoliceState.value;
    _needFire = _needFireState.value;
    _needAmbulance = _needAmbulanceState.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  @override
  void dispose() {
    _needPoliceState.dispose();
    _needFireState.dispose();
    _needAmbulanceState.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
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
          _currentPosition!.latitude, _currentPosition!.longitude);
    }

    // Stream updates
    _locationSubscription?.cancel();
    _locationSubscription =
        locationService.getLocationStream().listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
      socketService.emitLocationUpdate(position.latitude, position.longitude);
    });

    // Prepare selected services
    final selectedServices = <String>[];
    if (_needPolice) selectedServices.add('police');
    if (_needFire) selectedServices.add('fire');
    if (_needAmbulance) selectedServices.add('ambulance');
    if (selectedServices.isEmpty) selectedServices.add('general');

    // === Check connectivity and call backend or use SMS fallback ===
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity == ConnectivityResult.none;

    if (isOffline) {
      // Offline fallback: open native SMS app to all contacts
      await _sendOfflineSMS(contacts);
    } else {
      try {
        final result = await _emergencyApi.triggerSOS(
          latitude: _currentPosition?.latitude ?? 23.8103,
          longitude: _currentPosition?.longitude ?? 90.4125,
          serviceTypes: selectedServices,
        );
        _activeAlertId = result['alert']?['_id']?.toString();

        if (mounted) {
          final s = ref.read(stringsProvider);
          final notifiedCount = result['contactsNotified'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${s.sosActiveStatus} $notifiedCount ${s.sosContactsNotified}',
                style: const TextStyle(fontFamily: 'HindSiliguri'),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        debugPrint('Backend SOS error, trying SMS fallback: $e');
        await _sendOfflineSMS(contacts);
      }
    }
  }

  /// Open native SMS app pre-filled with emergency contacts and location
  Future<void> _sendOfflineSMS(List<EmergencyContactModel> contacts) async {
    final s = ref.read(stringsProvider);
    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.sosNoContacts,
              style: const TextStyle(fontFamily: 'HindSiliguri'),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final lat = _currentPosition?.latitude ?? 0;
    final lng = _currentPosition?.longitude ?? 0;
    final locationText = lat != 0
        ? '${s.sosCurrentLocation} https://maps.google.com/?q=$lat,$lng'
        : s.sosLocationNotFound;
    final body = Uri.encodeComponent(
        '🆘 ${s.sosSmsBody} $locationText ${s.sosPleaseHelp}');

    // Build phone list (up to 5 contacts)
    final phones = contacts.take(5).map((c) => c.phoneNumber).join(',');
    final smsUri = Uri.parse('sms:$phones?body=$body');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.sosSmsAppOpened,
              style: const TextStyle(fontFamily: 'HindSiliguri'),
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: _isActivated
          ? const Color(0xFFD32F2F)
          : (isDark ? AppColors.backgroundDark : AppColors.background),
      appBar: AppBar(
        title: Text(s.sosTitle),
        backgroundColor: Colors.transparent,
        foregroundColor: _isActivated ? Colors.white : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              key: const PageStorageKey('sos_scroll'),
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    SizedBox(
                      height: _isActivating || _isActivated ? 420 : 360,
                      child: Center(
                        child: _isActivating
                            ? _buildCountdownView()
                            : _isActivated
                                ? _buildActivatedView()
                                : _buildSOSButton(),
                      ),
                    ),

                    // Service Selection
                    if (!_isActivating && !_isActivated)
                      _buildServiceSelection(isDark),

                    // Emergency contacts
                    if (!_isActivating && !_isActivated) ...[
                      _buildContactsSection(contacts, isDark),
                      const SizedBox(height: 16),
                      _buildEmergencyNumbers(isDark),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    final s = ref.watch(stringsProvider);
    final buttonSize = MediaQuery.of(context).size.width < 390 ? 184.0 : 200.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          s.sosPressHold,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: const Color(0xFFF44336).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      // ignore: deprecated_member_use
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          s.sosTitle,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'HindSiliguri',
                            letterSpacing: 2,
                            decoration: TextDecoration.none,
                          ),
                        ),
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

  Widget _buildServiceSelection(bool isDark) {
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.sosSelectService,
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildCheckbox(
                  s.sosPolice,
                  _needPolice,
                  (v) => setState(() {
                        _needPolice = v!;
                        _needPoliceState.value = v;
                      })),
              _buildCheckbox(
                  s.sosFire,
                  _needFire,
                  (v) => setState(() {
                        _needFire = v!;
                        _needFireState.value = v;
                      })),
              _buildCheckbox(
                  s.sosAmbulance,
                  _needAmbulance,
                  (v) => setState(() {
                        _needAmbulance = v!;
                        _needAmbulanceState.value = v;
                      })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.error,
            visualDensity: VisualDensity.compact,
          ),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownView() {
    final s = ref.watch(stringsProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${s.sosActivating}...',
          style: const TextStyle(
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
            // ignore: deprecated_member_use
            color: AppColors.error.withOpacity(0.1),
            border: Border.all(color: AppColors.error, width: 4),
          ),
          child: Center(
            child: Text(
              '$_countdown',
              style: const TextStyle(
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
          label: Text(
            s.cancel,
            style: const TextStyle(
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
    final s = ref.watch(stringsProvider);
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
          s.sosActivated,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'HindSiliguri',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.sosAlertSent,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'HindSiliguri',
          ),
        ),
        if (_currentPosition != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  s.sosLocationShared,
                  style: const TextStyle(
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
          label: Text(
            s.sosSafeBtn,
            style: const TextStyle(fontFamily: 'HindSiliguri'),
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

  Widget _buildContactsSection(
      List<EmergencyContactModel> contacts, bool isDark) {
    final s = ref.watch(stringsProvider);
    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardDecoration(context: context),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.sosAddContacts,
                  style: const TextStyle(
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
            '${s.sosEmergencyContacts} (${contacts.length})',
            style: const TextStyle(
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
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: const TextStyle(
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
                            style: const TextStyle(
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
                    const Icon(
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
    final s = ref.watch(stringsProvider);
    final numbers = [
      {'name': s.sosNumberNational, 'number': '999'},
      {'name': s.sosNumberFire, 'number': '199'},
      {'name': s.sosNumberAmbulance, 'number': '199'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.sosEmergencyNumbers,
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: numbers
                .map((n) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(12),
                        decoration:
                            AppDecorations.cardDecoration(context: context),
                        child: Column(
                          children: [
                            Text(
                              n['number']!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n['name']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'HindSiliguri',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
