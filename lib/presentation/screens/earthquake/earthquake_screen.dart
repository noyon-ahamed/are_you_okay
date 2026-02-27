import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../services/api/earthquake_service.dart';

class EarthquakeScreen extends ConsumerStatefulWidget {
  const EarthquakeScreen({super.key});

  @override
  ConsumerState<EarthquakeScreen> createState() => _EarthquakeScreenState();
}

class _EarthquakeScreenState extends ConsumerState<EarthquakeScreen> {
  bool _isLoading = true;
  String? _error;
  List<_EarthquakeData> _localQuakes = [];
  List<_EarthquakeData> _globalQuakes = [];

  @override
  void initState() {
    super.initState();
    _fetchEarthquakeData();
  }

  Future<void> _fetchEarthquakeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      double? lat;
      double? lng;

      // Try to get current location to filter earthquake data
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('Location services disabled');
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          
          // Request permission if denied
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          
          // If permanently denied, show dialog to open settings
          if (permission == LocationPermission.deniedForever) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'লোকেশন পারমিশন প্রয়োজন। অনুগ্রহ করে সেটিংস থেকে অনুমতি দিন।',
                    style: TextStyle(fontFamily: 'HindSiliguri'),
                  ),
                  action: SnackBarAction(
                    label: 'সেটিংস',
                    onPressed: () => Geolocator.openAppSettings(),
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
          
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (e) {
        debugPrint('Could not fetch location directly: $e');
      }

      final earthquakeService = ref.read(earthquakeServiceProvider);
      final responseData = await earthquakeService.getLatestEarthquakes(lat: lat, lng: lng);

      if (mounted) {
        setState(() {
          _localQuakes = _parseQuakes(responseData['localAlerts'] as List?, lat, lng);
          _globalQuakes = _parseQuakes(responseData['globalAlerts'] as List?, lat, lng);
          _isLoading = false;
        });

        // Check for dangerous earthquakes in local vicinity and play siren
        final dangerous = _localQuakes.where((q) => q.magnitude >= 6.0);
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
      appBar: AppBar(
        title: const Text(
          'ভূমিকম্প সতর্কতা',
          style: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEarthquakeData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingList()
          : _error != null
              ? _buildErrorView()
              : (_localQuakes.isEmpty && _globalQuakes.isEmpty)
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _fetchEarthquakeData,
                      child: _buildHistoryList(context, isDark),
                    ),
    );
  }

  List<_EarthquakeData> _parseQuakes(List? dataList, double? userLat, double? userLng) {
    if (dataList == null) return [];
    return dataList.map((e) {
      final coords = e['location']?['coordinates'] as List?;
      final eqLng = (coords != null && coords.isNotEmpty) ? (coords[0] as num).toDouble() : 0.0;
      final eqLat = (coords != null && coords.length > 1) ? (coords[1] as num).toDouble() : 0.0;
      final magnitude = (e['magnitude'] as num?)?.toDouble() ?? 0.0;
      final timestampStr = e['time']?.toString() ?? e['timestamp']?.toString() ?? '';
      final timestamp = DateTime.tryParse(timestampStr) ?? DateTime.now();

      double? displayDistance;
      // Backend returns 'distance' key for local alerts
      if (e['distance'] != null) {
        if (e['distance'] is num) {
          displayDistance = (e['distance'] as num).toDouble();
        } else if (e['distance'] is String) {
          displayDistance = double.tryParse(e['distance']);
        }
      } 
      // Fallback calculation if not present but we have coordinates
      if (displayDistance == null && userLat != null && userLng != null && eqLat != 0.0 && eqLng != 0.0) {
        displayDistance = Geolocator.distanceBetween(userLat, userLng, eqLat, eqLng) / 1000;
      }

      return _EarthquakeData(
        eventId: e['eventId']?.toString() ?? '',
        magnitude: magnitude,
        location: e['place']?.toString() ?? 'Unknown',
        time: timeago.format(timestamp),
        latitude: eqLat,
        longitude: eqLng,
        depth: '${(e['depth'] as num?)?.toStringAsFixed(0) ?? '?'} km',
        timestamp: timestamp,
        distanceKm: displayDistance,
      );
    }).toList();
  }

  Widget _buildHistoryList(BuildContext context, bool isDark) {
    // Highest magnitude calculation (using both sets for stats, or just local. Let's use local for stats to be relevant to user)
    double highestMag = 0.0;
    int highMagnitudeCount = 0;

    for (var quake in _localQuakes) {
      if (quake.magnitude > highestMag) highestMag = quake.magnitude;
      if (quake.magnitude >= 4.5) highMagnitudeCount++;
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _buildStatsHeader(context, isDark, highestMag, highMagnitudeCount),
          ),
        ),

        // Local Header
        if (_localQuakes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'আপনার কাছাকাছি (৩০০০ কি.মি)',
                style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Local Timeline list
        if (_localQuakes.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuakeItem(context, _localQuakes[index], isDark),
                );
              },
              childCount: _localQuakes.length,
            ),
          ),

        // Global Header
        if (_globalQuakes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
              child: Text(
                'বিশ্বের বড় ভূমিকম্প (টপ ৫)',
                style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Global Timeline list
        if (_globalQuakes.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuakeItem(context, _globalQuakes[index], isDark),
                );
              },
              childCount: _globalQuakes.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildStatsHeader(
    BuildContext context,
    bool isDark,
    double highestMag,
    int highMagnitudeCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF795548),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.my_location,
            value: '${_localQuakes.length}',
            label: 'কাছাকাছি',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.warning_amber_rounded,
            value: highestMag.toStringAsFixed(1),
            label: 'সর্বোচ্চ মাত্রা',
            color: highestMag >= 6.0 ? AppColors.error : Colors.white,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.bolt,
            value: '$highMagnitudeCount',
            label: '৪.৫+ মাত্রা',
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'HindSiliguri',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }

  Future<void> _launchMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $uri');
    }
  }

  Widget _buildQuakeItem(BuildContext context, _EarthquakeData quake, bool isDark) {
    Color magColor;
    if (quake.magnitude >= 6.0) {
      magColor = AppColors.error;
    } else if (quake.magnitude >= 4.5) {
      magColor = const Color(0xFFFF9800);
    } else {
      magColor = AppColors.success;
    }

    return GestureDetector(
      onTap: () => _launchMap(quake.latitude, quake.longitude),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                    if (quake.distanceKm != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${quake.distanceKm!.toStringAsFixed(0)} কি.মি. দূরে',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
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
            const Text(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 5,
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
}

class _EarthquakeData {
  final String eventId;
  final double magnitude;
  final String location;
  final String time;
  final double latitude;
  final double longitude;
  final String depth;
  final DateTime timestamp;
  final double? distanceKm;

  _EarthquakeData({
    required this.eventId,
    required this.magnitude,
    required this.location,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.timestamp,
    this.distanceKm,
  });
}
