import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../services/api/earthquake_service.dart';

class EarthquakeScreen extends ConsumerStatefulWidget {
  const EarthquakeScreen({super.key});

  @override
  ConsumerState<EarthquakeScreen> createState() => _EarthquakeScreenState();
}

class _EarthquakeScreenState extends ConsumerState<EarthquakeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _isLoading = true;
  String? _error;
  List<_EarthquakeData> _recentQuakes = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Bangladesh bounds
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.6850, 90.3563),
    zoom: 6.5,
  );

  @override
  void initState() {
    super.initState();
    _fetchEarthquakeData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchEarthquakeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final earthquakeService = ref.read(earthquakeServiceProvider);
      final data = await earthquakeService.getLatestEarthquakes();

      if (mounted) {
        setState(() {
          _recentQuakes = data.map((e) {
            final coords = e['location']?['coordinates'] as List?;
            final lng = coords != null && coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
            final lat = coords != null && coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;
            final magnitude = (e['magnitude'] as num?)?.toDouble() ?? 0.0;
            final timestamp = DateTime.tryParse(e['timestamp']?.toString() ?? '') ?? DateTime.now();

            return _EarthquakeData(
              eventId: e['eventId']?.toString() ?? '',
              magnitude: magnitude,
              location: e['place']?.toString() ?? 'Unknown',
              time: timeago.format(timestamp),
              latLng: LatLng(lat, lng),
              depth: '${(e['depth'] as num?)?.toStringAsFixed(0) ?? '?'} km',
              timestamp: timestamp,
            );
          }).toList();
          _isLoading = false;
        });

        // Check for dangerous earthquakes and play siren
        final dangerous = _recentQuakes.where((q) => q.magnitude >= 6.0);
        if (dangerous.isNotEmpty) {
          _playSirenAlert();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _playSirenAlert() async {
    try {
      // Use a built-in alert sound or asset
      // For now, just show a notification-style alert
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.error,
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  '⚠️ বিপদ সংকেত!',
                  style: TextStyle(color: Colors.white, fontFamily: 'HindSiliguri'),
                ),
              ],
            ),
            content: const Text(
              'উচ্চ মাত্রার ভূমিকম্প শনাক্ত হয়েছে! নিরাপদ স্থানে যান!',
              style: TextStyle(color: Colors.white, fontFamily: 'HindSiliguri'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('বুঝেছি', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Siren error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ==================== Map Background ====================
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _recentQuakes.map((quake) {
              return Marker(
                markerId: MarkerId(quake.eventId.isEmpty ? quake.location : quake.eventId),
                position: quake.latLng,
                infoWindow: InfoWindow(
                  title: '${quake.magnitude} মাত্রা',
                  snippet: quake.location,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  quake.magnitude >= 6.0
                      ? BitmapDescriptor.hueRed
                      : quake.magnitude >= 4.5
                          ? BitmapDescriptor.hueOrange
                          : BitmapDescriptor.hueYellow,
                ),
              );
            }).toSet(),
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // ==================== Top Gradient Overlay ====================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ভূমিকম্প সতর্কতা',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'HindSiliguri',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _fetchEarthquakeData,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==================== Bottom Sheet List ====================
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.public, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'সাম্প্রতিক ভূমিকম্প (${_recentQuakes.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'HindSiliguri',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingList()
                        : _error != null
                            ? _buildErrorView()
                            : _recentQuakes.isEmpty
                                ? _buildEmptyView()
                                : RefreshIndicator(
                                    onRefresh: _fetchEarthquakeData,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _recentQuakes.length,
                                      itemBuilder: (context, index) {
                                        return _buildQuakeItem(
                                            context, _recentQuakes[index], isDark);
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'ডেটা লোড করতে ব্যর্থ',
              style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchEarthquakeData,
              icon: const Icon(Icons.refresh),
              label: const Text('আবার চেষ্টা করুন', style: TextStyle(fontFamily: 'HindSiliguri')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            const SizedBox(height: 12),
            Text(
              'কোনো সাম্প্রতিক ভূমিকম্প নেই',
              style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuakeItem(
      BuildContext context, _EarthquakeData quake, bool isDark) {
    Color magColor;
    if (quake.magnitude >= 6.0) {
      magColor = AppColors.error;
    } else if (quake.magnitude >= 4.5) {
      magColor = const Color(0xFFFF9800);
    } else {
      magColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardDecoration(context: context),
      child: Row(
        children: [
          // Magnitude Circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: magColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: magColor, width: 2),
            ),
            child: Center(
              child: Text(
                quake.magnitude.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: magColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quake.location,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quake.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.layers,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quake.depth,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (quake.magnitude >= 6.0)
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24)
          else
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).dividerColor,
            ),
        ],
      ),
    );
  }
}

class _EarthquakeData {
  final String eventId;
  final double magnitude;
  final String location;
  final String time;
  final LatLng latLng;
  final String depth;
  final DateTime timestamp;

  _EarthquakeData({
    required this.eventId,
    required this.magnitude,
    required this.location,
    required this.time,
    required this.latLng,
    required this.depth,
    required this.timestamp,
  });
}
