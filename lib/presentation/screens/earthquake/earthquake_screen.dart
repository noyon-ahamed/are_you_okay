import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/earthquake_countries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/settings_provider.dart';
import '../../../services/api/auth_api_service.dart';
import '../../../services/api/earthquake_service.dart';
import '../../../services/location_service.dart';
import '../../../provider/language_provider.dart';
import '../../../core/localization/app_strings.dart';

class EarthquakeScreen extends ConsumerStatefulWidget {
  const EarthquakeScreen({super.key});

  @override
  ConsumerState<EarthquakeScreen> createState() => _EarthquakeScreenState();
}

class _EarthquakeScreenState extends ConsumerState<EarthquakeScreen>
    with RestorationMixin, SingleTickerProviderStateMixin {
  static const int _nearbyRadiusKm = 3000;
  final RestorableInt _selectedTab = RestorableInt(0);
  late final TabController _tabController;
  bool _isLoading = true;
  bool _showingCachedData = false;
  String? _error;
  String _selectedCountry = '';
  List<_EarthquakeData> _localQuakes = [];
  List<_EarthquakeData> _countryQuakes = [];
  List<_EarthquakeData> _globalQuakes = [];
  final Set<String> _shownDangerAlerts = <String>{};

  @override
  String? get restorationId => 'earthquake_screen';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          _selectedTab.value = _tabController.index;
        }
      });
    _bootstrapEarthquakeData();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedTab, 'selected_tab');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index != _selectedTab.value) {
        _tabController.index = _selectedTab.value;
      }
    });
  }

  @override
  void dispose() {
    _selectedTab.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasVisibleData =>
      _localQuakes.isNotEmpty ||
      _countryQuakes.isNotEmpty ||
      _globalQuakes.isNotEmpty;

  Future<void> _bootstrapEarthquakeData() async {
    final earthquakeService = ref.read(earthquakeServiceProvider);
    final sessionOverride = ref.read(earthquakeCountryOverrideProvider);
    final selectedCountry =
        sessionOverride ?? ref.read(settingsProvider).earthquakeCountry.trim();
    final lastKnownLocation =
        await ref.read(locationServiceProvider).getLastKnownLocation();
    final cached = await earthquakeService.getCachedEarthquakes(
      lat: lastKnownLocation?.latitude,
      lng: lastKnownLocation?.longitude,
      country: selectedCountry,
    );
    if (mounted && cached != null) {
      _applyEarthquakeResponse(cached, allowCachedState: true);
    }
    await _fetchEarthquakeData();
  }

  Future<void> _fetchEarthquakeData() async {
    final s = ref.read(stringsProvider);
    final sessionOverride = ref.read(earthquakeCountryOverrideProvider);
    var selectedCountry =
        sessionOverride ?? ref.read(settingsProvider).earthquakeCountry.trim();
    final locationService = ref.read(locationServiceProvider);
    final hasVisibleData = _hasVisibleData;

    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!hasVisibleData) {
            _error = 'offline';
          }
        });
      }
      return;
    }

    if (!hasVisibleData) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final serviceEnabled = await locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationRequiredDialog(
          s: s,
          openSettings: locationService.openLocationSettings,
        );
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (!hasVisibleData) {
            _error = 'location_required';
          }
        });
        return;
      }

      var permission = await locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await locationService.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _showLocationRequiredDialog(
          s: s,
          openSettings: permission == LocationPermission.deniedForever
              ? locationService.openAppSettings
              : locationService.openLocationSettings,
        );
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (!hasVisibleData) {
            _error = 'location_required';
          }
        });
        return;
      }

      final position = await locationService.getLastKnownLocation() ??
          await locationService
              .getCurrentLocation(accuracy: LocationAccuracy.low)
              .timeout(const Duration(seconds: 6), onTimeout: () => null);
      if (position == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (!hasVisibleData) {
              _error = 'location_required';
            }
          });
        }
        return;
      }
      final lat = position.latitude;
      final lng = position.longitude;

      unawaited(
        AuthApiService()
            .updateLocation(
          latitude: lat,
          longitude: lng,
        )
            .catchError((e) {
          debugPrint('Could not sync user location: $e');
        }),
      );

      final detectedCountryFuture = locationService
          .getCountryFromCoordinates(
            latitude: lat,
            longitude: lng,
          )
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      String? detectedCountry;
      if (selectedCountry.isEmpty) {
        detectedCountry = await detectedCountryFuture;
      } else {
        unawaited(
          detectedCountryFuture.then((country) async {
            if (sessionOverride == null &&
                country != null &&
                EarthquakeCountries.supported.contains(country) &&
                country !=
                    ref.read(settingsProvider).earthquakeCountry.trim()) {
              await ref
                  .read(settingsProvider.notifier)
                  .setEarthquakeCountry(country);
            }
          }),
        );
      }

      if (sessionOverride == null &&
          detectedCountry != null &&
          EarthquakeCountries.supported.contains(detectedCountry) &&
          detectedCountry != selectedCountry) {
        selectedCountry = detectedCountry;
        await ref
            .read(settingsProvider.notifier)
            .setEarthquakeCountry(detectedCountry);
      }

      if (selectedCountry.isEmpty) {
        selectedCountry = detectedCountry != null &&
                EarthquakeCountries.supported.contains(detectedCountry)
            ? detectedCountry
            : '';
      }

      final earthquakeService = ref.read(earthquakeServiceProvider);
      final responseData = await earthquakeService.getLatestEarthquakes(
        lat: lat,
        lng: lng,
        country: selectedCountry,
      );

      if (mounted) {
        _applyEarthquakeResponse(
          responseData,
          lat: lat,
          lng: lng,
          fallbackCountry: selectedCountry,
        );

        // Check for dangerous earthquakes in local vicinity and play siren
        final dangerous = [
          ..._localQuakes.where(_shouldTriggerDangerAlert),
          ..._countryQuakes.where(_shouldTriggerCountryAlert),
        ];
        if (dangerous.isNotEmpty) {
          _playSirenAlert(dangerous.first);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!hasVisibleData) {
            _error = e.toString();
          }
        });
      }
    }
  }

  void _applyEarthquakeResponse(
    Map<String, dynamic> responseData, {
    double? lat,
    double? lng,
    String fallbackCountry = '',
    bool allowCachedState = false,
  }) {
    final parsedLocal =
        _parseQuakes(responseData['localAlerts'] as List?, lat, lng);
    parsedLocal.sort((a, b) {
      final aDistance = a.distanceKm ?? double.infinity;
      final bDistance = b.distanceKm ?? double.infinity;
      final distanceCompare = aDistance.compareTo(bDistance);
      if (distanceCompare != 0) return distanceCompare;
      return b.timestamp.compareTo(a.timestamp);
    });
    final parsedCountry =
        _parseQuakes(responseData['countryAlerts'] as List?, lat, lng);
    final parsedGlobal =
        _parseQuakes(responseData['globalAlerts'] as List?, lat, lng);
    parsedGlobal.sort((a, b) => b.magnitude.compareTo(a.magnitude));

    setState(() {
      _selectedCountry =
          responseData['selectedCountry']?.toString() ?? fallbackCountry;
      _localQuakes = parsedLocal;
      _countryQuakes = parsedCountry.isEmpty
          ? _buildCountryFallbackQuakes(
              selectedCountry: _selectedCountry,
              localQuakes: parsedLocal,
              globalQuakes: parsedGlobal,
            )
          : parsedCountry;
      _globalQuakes = parsedGlobal.take(5).toList();
      _showingCachedData =
          allowCachedState || responseData['_fromCache'] == true;
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _showLocationRequiredDialog({
    required AppStrings s,
    required Future<bool> Function() openSettings,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          s.earthquakeLocTitle,
          style: const TextStyle(fontFamily: 'HindSiliguri'),
        ),
        content: Text(
          s.earthquakeLocBody,
          style: const TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              s.retry,
              style: const TextStyle(fontFamily: 'HindSiliguri'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openSettings();
            },
            child: Text(
              s.earthquakeSettings,
              style: const TextStyle(fontFamily: 'HindSiliguri'),
            ),
          ),
        ],
      ),
    );
  }

  List<_EarthquakeData> _buildCountryFallbackQuakes({
    required String selectedCountry,
    required List<_EarthquakeData> localQuakes,
    required List<_EarthquakeData> globalQuakes,
  }) {
    final normalizedCountry = selectedCountry.trim().toLowerCase();
    final seen = <String>{};
    final combined = <_EarthquakeData>[
      ...localQuakes,
      ...globalQuakes,
    ];

    final matched = combined.where((quake) {
      final location = quake.location.toLowerCase();
      return normalizedCountry.isNotEmpty &&
          location.contains(normalizedCountry);
    }).where((quake) {
      final key = quake.eventId.isNotEmpty
          ? quake.eventId
          : '${quake.location}-${quake.timestamp.toIso8601String()}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    matched.sort((a, b) {
      final timeCompare = b.timestamp.compareTo(a.timestamp);
      if (timeCompare != 0) return timeCompare;
      return b.magnitude.compareTo(a.magnitude);
    });

    return matched.take(10).toList();
  }

  bool _shouldTriggerDangerAlert(_EarthquakeData quake) {
    final age = DateTime.now().difference(quake.timestamp);
    final isRecent = age.inMinutes <= 15;
    final isClose = quake.distanceKm != null && quake.distanceKm! <= 100;
    final alreadyShown = _shownDangerAlerts.contains(quake.eventId);
    return quake.magnitude >= 4.5 &&
        isRecent &&
        isClose &&
        !alreadyShown &&
        quake.eventId.isNotEmpty;
  }

  bool _shouldTriggerCountryAlert(_EarthquakeData quake) {
    final age = DateTime.now().difference(quake.timestamp);
    final isRecent = age.inMinutes <= 15;
    final alreadyShown = _shownDangerAlerts.contains(quake.eventId);
    return quake.magnitude >= 6.0 &&
        isRecent &&
        !alreadyShown &&
        quake.eventId.isNotEmpty;
  }

  Future<void> _playSirenAlert(_EarthquakeData quake) async {
    try {
      _shownDangerAlerts.add(quake.eventId);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final s = ref.read(stringsProvider);
            return AlertDialog(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    s.earthquakeAlertTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'HindSiliguri',
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emergency_share,
                      color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    '${s.earthquakeAlertMessage}\n\n${quake.location}\n${quake.magnitude.toStringAsFixed(1)}M',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'HindSiliguri',
                        fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(backgroundColor: Colors.white),
                  child: Text(s.earthquakeUnderstood,
                      style: const TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Siren error: $e');
    }
  }

  List<_EarthquakeData> _parseQuakes(
      List? dataList, double? userLat, double? userLng) {
    if (dataList == null) return [];
    return dataList.map((e) {
      final coords = e['location']?['coordinates'] as List?;
      final eqLng = (coords != null && coords.isNotEmpty)
          ? (coords[0] as num).toDouble()
          : 0.0;
      final eqLat = (coords != null && coords.length > 1)
          ? (coords[1] as num).toDouble()
          : 0.0;
      final magnitude = (e['magnitude'] as num?)?.toDouble() ?? 0.0;
      final timestampStr =
          e['time']?.toString() ?? e['timestamp']?.toString() ?? '';
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
      if (displayDistance == null &&
          userLat != null &&
          userLng != null &&
          eqLat != 0.0 &&
          eqLng != 0.0) {
        displayDistance =
            Geolocator.distanceBetween(userLat, userLng, eqLat, eqLng) / 1000;
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.earthquakeTitle,
          style: const TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEarthquakeData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
              fontFamily: 'HindSiliguri', fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontFamily: 'HindSiliguri'),
          tabs: [
            Tab(
              text: _selectedCountry.isEmpty
                  ? s.earthquakeTabCountry
                  : _selectedCountry,
            ),
            Tab(text: s.earthquakeTabNearWithRadius(_nearbyRadiusKm)),
            Tab(text: s.earthquakeTabGlobal),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingList()
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _fetchEarthquakeData,
                      child: _buildTabContent(
                        context,
                        _countryQuakes,
                        s,
                        false,
                        headerMessage: s.earthquakeCountryRecent(_selectedCountry),
                      ),
                    ),
                    // TAB 1: Near Me
                    RefreshIndicator(
                      onRefresh: _fetchEarthquakeData,
                      child: _buildTabContent(
                        context,
                        _localQuakes,
                        s,
                        true,
                        headerMessage: s.earthquakeNearMeRecent(_nearbyRadiusKm),
                      ),
                    ),
                    // TAB 2: Global
                    RefreshIndicator(
                      onRefresh: _fetchEarthquakeData,
                      child: _buildTabContent(
                        context,
                        _globalQuakes,
                        s,
                        false,
                        headerMessage: s.earthquakeGlobalRecent,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<_EarthquakeData> quakes,
      AppStrings s, bool isLocal,
      {String? headerMessage}) {
    if (quakes.isEmpty) {
      return _buildEmptyView(s);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Stats for local only
    double? highestMag;
    int? highCount;
    if (isLocal) {
      highestMag = 0.0;
      highCount = 0;
      for (var q in quakes) {
        if (q.magnitude > highestMag!) highestMag = q.magnitude;
        if (q.magnitude >= 4.5) highCount = highCount! + 1;
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        if (_showingCachedData)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  s.earthquakeCachedData,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        if (headerMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  headerMessage,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        if (isLocal && highestMag != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildStatsHeader(
                  context, isDark, highestMag, highCount ?? 0, s),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildQuakeItem(context, quakes[index], isDark);
              },
              childCount: quakes.length,
            ),
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
    AppStrings s,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFF795548),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.my_location,
            value: '${_localQuakes.length}',
            label: s.earthquakeNearbyStat,
          ),
          Container(
            width: 1,
            height: 40,
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.warning_amber_rounded,
            value: highestMag.toStringAsFixed(1),
            label: s.earthquakeMaxMag,
            color: highestMag >= 6.0 ? AppColors.error : Colors.white,
          ),
          Container(
            width: 1,
            height: 40,
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.bolt,
            value: '$highMagnitudeCount',
            label: s.earthquakeMag45,
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
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }

  Future<void> _launchMap(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $uri');
    }
  }

  Widget _buildQuakeItem(
      BuildContext context, _EarthquakeData quake, bool isDark) {
    final s = ref.watch(stringsProvider);
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
                // ignore: deprecated_member_use
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
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
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
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
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
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${quake.distanceKm!.toStringAsFixed(1)} ${s.earthquakeAway}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
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
    final bool isOffline = _error == 'offline';
    final bool isLocationRequired = _error == 'location_required';
    final s = ref.watch(stringsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocationRequired
                  ? Icons.location_off_rounded
                  : isOffline
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline,
              size: 64,
              color: isLocationRequired
                  ? AppColors.primary
                  : isOffline
                      ? AppColors.warning
                      : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isLocationRequired
                  ? (s.isBangla ? 'লোকেশন দরকার' : 'Location required')
                  : isOffline
                      ? s.earthquakeOffline
                      : s.networkError,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isLocationRequired
                  ? (s.isBangla
                      ? 'ভূমিকম্প ডাটা দেখতে লোকেশন সার্ভিস ও পারমিশন চালু করুন।'
                      : 'Enable location services and permission to load earthquake data.')
                  : isOffline
                      ? s.earthquakeOfflineMessage
                      : s.earthquakeServerError,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchEarthquakeData,
              icon: Icon(
                isLocationRequired ? Icons.my_location_rounded : Icons.refresh,
              ),
              label: Text(
                isLocationRequired
                    ? (s.isBangla
                        ? 'লোকেশন দিয়ে আবার চেষ্টা করুন'
                        : 'Enable location and retry')
                    : s.retry,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.success),
            const SizedBox(height: 12),
            Text(
              s.earthquakeEmpty,
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
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
