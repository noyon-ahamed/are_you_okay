import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob Service
/// Handles Google AdMob integration
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Ad Unit IDs
  // TODO: Replace with actual AdMob unit IDs
  static final String bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Test ID
      : 'ca-app-pub-3940256099942544/2934735716'; // Test ID

  static final String interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Test ID
      : 'ca-app-pub-3940256099942544/4411468910'; // Test ID

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  // Ad state
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  
  // Ad frequency control
  DateTime? _lastInterstitialShown;
  static const Duration _interstitialCooldown = Duration(hours: 24);

  /// Initialize AdMob
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      debugPrint('AdMob initialized');
      
      // Preload interstitial ad
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('Error initializing AdMob: $e');
    }
  }

  /// Load banner ad
  void loadBannerAd({
    required Function() onAdLoaded,
    required Function(LoadAdError error) onAdFailedToLoad,
  }) {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
          _isBannerAdLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          _isBannerAdLoaded = false;
          ad.dispose();
          onAdFailedToLoad(error);
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
      ),
    );

    _bannerAd!.load();
  }

  /// Get banner ad
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  /// Dispose banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  /// Load interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          // Set full screen content callback
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Interstitial ad showed full screen content');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              
              // Preload next ad
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              
              // Retry loading
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () {
            _loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Show interstitial ad (with frequency control)
  Future<bool> maybeShowInterstitialAd({
    bool forceShow = false,
  }) async {
    // Check cooldown period
    if (!forceShow && _lastInterstitialShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialShown!);
      if (timeSinceLastAd < _interstitialCooldown) {
        debugPrint('Interstitial ad still in cooldown period');
        return false;
      }
    }

    // Show ad if loaded
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      _lastInterstitialShown = DateTime.now();
      return true;
    } else {
      debugPrint('Interstitial ad not ready');
      return false;
    }
  }

  /// Check if interstitial ad is ready
  bool get isInterstitialAdReady => _isInterstitialAdLoaded;

  /// Check if can show interstitial (respects cooldown)
  bool get canShowInterstitial {
    if (_lastInterstitialShown == null) return true;
    
    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialShown!);
    return timeSinceLastAd >= _interstitialCooldown;
  }

  /// Dispose all ads
  void dispose() {
    disposeBannerAd();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  /// Reset interstitial cooldown (for testing)
  void resetInterstitialCooldown() {
    _lastInterstitialShown = null;
  }
}
