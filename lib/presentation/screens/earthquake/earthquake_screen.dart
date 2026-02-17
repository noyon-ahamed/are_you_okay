import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';

class EarthquakeScreen extends StatefulWidget {
  const EarthquakeScreen({super.key});

  @override
  State<EarthquakeScreen> createState() => _EarthquakeScreenState();
}

class _EarthquakeScreenState extends State<EarthquakeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _isLoading = true;
  List<_EarthquakeData> _recentQuakes = [];

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

  Future<void> _fetchEarthquakeData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _recentQuakes = [
          _EarthquakeData(
            magnitude: 4.2,
            location: 'সিলেট, বাংলাদেশ',
            time: '১০ মিনিট আগে',
            latLng: const LatLng(24.8949, 91.8687),
            depth: '১০ কিমি',
          ),
          _EarthquakeData(
            magnitude: 3.8,
            location: 'চট্টগ্রাম, বাংলাদেশ',
            time: '২ ঘণ্টা আগে',
            latLng: const LatLng(22.3569, 91.7832),
            depth: '৫ কিমি',
          ),
          _EarthquakeData(
            magnitude: 5.1,
            location: 'মায়ানমার সীমান্ত',
            time: '১ দিন আগে',
            latLng: const LatLng(21.2, 92.5),
            depth: '১৫ কিমি',
          ),
        ];
        _isLoading = false;
      });
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
            mapType: isDark ? MapType.normal : MapType.normal, // TODO: Custom dark style
            initialCameraPosition: _initialPosition,
            markers: _recentQuakes.map((quake) {
              return Marker(
                markerId: MarkerId(quake.location),
                position: quake.latLng,
                infoWindow: InfoWindow(
                  title: '${quake.magnitude} মাত্রা',
                  snippet: quake.location,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  quake.magnitude >= 5.0
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueOrange,
                ),
              );
            }).toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              if (isDark) {
                // TODO: Set dark map style
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
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchEarthquakeData();
                        },
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
                        const Text(
                          'সাম্প্রতিক ভূমিকম্প',
                          style: TextStyle(
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
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _recentQuakes.length,
                            itemBuilder: (context, index) {
                              return _buildQuakeItem(
                                  context, _recentQuakes[index], isDark);
                            },
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
      magColor = const Color(0xFFFF9800); // Warning
    } else {
      magColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardDecoration(context: context),
      child: Row(
        children: [
          // Look Circle
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
                quake.magnitude.toString(),
                style: TextStyle(
                  fontSize: 18,
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
                    fontSize: 15,
                    fontFamily: 'HindSiliguri',
                  ),
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
                        fontFamily: 'HindSiliguri',
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
                        fontFamily: 'HindSiliguri',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Arrow
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
  final double magnitude;
  final String location;
  final String time;
  final LatLng latLng;
  final String depth;

  _EarthquakeData({
    required this.magnitude,
    required this.location,
    required this.time,
    required this.latLng,
    required this.depth,
  });
}
