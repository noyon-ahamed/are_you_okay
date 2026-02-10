import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/admob_service.dart';
import '../../services/api/config_api_service.dart';

/// Banner Ad Widget
/// Displays AdMob banner ad only if enabled in backend config
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final _adService = AdMobService();
  final _configService = ConfigApiService();
  bool _isAdLoaded = false;
  bool _adsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkConfigAndLoadAd();
  }

  Future<void> _checkConfigAndLoadAd() async {
    try {
      // Fetch config from backend
      final config = await _configService.getConfig();
      final adsEnabled = config['adsEnabled'] ?? false;

      if (!mounted) return;

      setState(() {
        _adsEnabled = adsEnabled;
      });

      // Only load ad if enabled
      if (adsEnabled) {
        _loadAd();
      }
    } catch (error) {
      // If config fetch fails, don't show ads
      if (mounted) {
        setState(() {
          _adsEnabled = false;
        });
      }
    }
  }

  void _loadAd() {
    _adService.loadBannerAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (error) {
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _adService.disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ad if not enabled or not loaded
    if (!_adsEnabled || !_isAdLoaded || _adService.bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _adService.bannerAd!.size.width.toDouble(),
      height: _adService.bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _adService.bannerAd!),
    );
  }
}
