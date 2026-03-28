import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../provider/language_provider.dart';
import '../../../provider/splash_provider.dart';
import '../../../services/api/config_api_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  final ConfigApiService _configApiService = ConfigApiService();
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _shimmerController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _pulse;
  late Animation<double> _progress;
  late Animation<double> _shimmer;
  bool _isBlockingLaunch = false;
  String? _blockTitle;
  String? _blockMessage;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    _runLaunchChecks();
  }

  Future<void> _runLaunchChecks() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    try {
      final config = await _configApiService.getConfig();
      final maintenanceMode = config['maintenanceMode'] == true;
      final minAppVersion =
          ((config['minAppVersion'] as Map<String, dynamic>?) ??
                  const <String, dynamic>{})[Platform.isIOS ? 'ios' : 'android']
              ?.toString();

      if (!mounted) return;

      if (maintenanceMode) {
        setState(() {
          _isBlockingLaunch = true;
          _blockTitle = 'Maintenance mode is enabled';
          _blockMessage =
              'The app is temporarily unavailable. Please try again a little later.';
        });
        return;
      }

      if (_isVersionLower(
        AppConstants.appVersion,
        minAppVersion ?? AppConstants.appVersion,
      )) {
        setState(() {
          _isBlockingLaunch = true;
          _blockTitle = 'Update required';
          _blockMessage =
              'Your app version is ${AppConstants.appVersion}. Please update to at least ${minAppVersion ?? AppConstants.appVersion} to continue.';
        });
        return;
      }
    } catch (_) {
      // Config fetch is best-effort. If it fails, allow the app to continue.
    }

    if (mounted) {
      ref.read(splashDisplayCompleteProvider.notifier).state = true;
    }
  }

  bool _isVersionLower(String currentVersion, String minimumVersion) {
    final currentParts = currentVersion
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final minimumParts = minimumVersion
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    final maxLength = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var index = 0; index < maxLength; index++) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final minimumPart = index < minimumParts.length ? minimumParts[index] : 0;

      if (currentPart < minimumPart) return true;
      if (currentPart > minimumPart) return false;
    }

    return false;
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    // Logo
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Text
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Pulse
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Progress bar — easing curve দিয়ে natural feel
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Shimmer
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = ref.watch(stringsProvider);

    if (_isBlockingLaunch) {
      return Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF003D2E),
                Color(0xFF005C42),
                Color(0xFF006A4E),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.system_update_alt_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _blockTitle ?? 'Please try again later',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _blockMessage ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isBlockingLaunch = false;
                            _blockTitle = null;
                            _blockMessage = null;
                          });
                          _runLaunchChecks();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.32),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF003D2E),
              Color(0xFF005C42),
              Color(0xFF006A4E),
              Color(0xFF1B8B6A),
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative rings
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: _ring(size.width * 0.7, 0.06),
            ),
            Positioned(
              top: -size.width * 0.15,
              right: -size.width * 0.35,
              child: _ring(size.width * 0.5, 0.04),
            ),
            Positioned(
              bottom: -size.width * 0.25,
              left: -size.width * 0.15,
              child: _ring(size.width * 0.6, 0.05),
            ),
            Positioned(
              bottom: -size.width * 0.1,
              left: -size.width * 0.3,
              child: _ring(size.width * 0.4, 0.03),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo with glow + pulse
                  SlideTransition(
                    position: _logoSlide,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _buildLogo(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          Text(
                            s.appName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppConstants.appName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              // ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.55),
                              letterSpacing: 4.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          FadeTransition(
                            opacity: _taglineOpacity,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                // ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  // ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                s.appTagline,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  // ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Progress bar section
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          // Progress bar
                          AnimatedBuilder(
                            animation: _progress,
                            builder: (context, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: SizedBox(
                                  height: 3,
                                  child: Stack(
                                    children: [
                                      // Track
                                      Container(
                                        decoration: BoxDecoration(
                                          // ignore: deprecated_member_use
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                      ),
                                      // Fill
                                      FractionallySizedBox(
                                        widthFactor: _progress.value,
                                        child: AnimatedBuilder(
                                          animation: _shimmer,
                                          builder: (context, _) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        // ignore: deprecated_member_use
                                                        .withOpacity(0.6),
                                                    Colors.white,
                                                    Colors.white
                                                        // ignore: deprecated_member_use
                                                        .withOpacity(0.6),
                                                  ],
                                                  stops: [
                                                    (_shimmer.value - 0.3)
                                                        .clamp(0.0, 1.0),
                                                    _shimmer.value
                                                        .clamp(0.0, 1.0),
                                                    (_shimmer.value + 0.3)
                                                        .clamp(0.0, 1.0),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          // Loading text
                          FadeTransition(
                            opacity: _taglineOpacity,
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (context, _) {
                                final percent = (_progress.value * 100).toInt();
                                return Text(
                                  '${s.splashLoading} $percent%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    // ignore: deprecated_member_use
                                    color: Colors.white.withOpacity(0.45),
                                    letterSpacing: 0.5,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Text(
                      'v${AppConstants.appVersion}',
                      style: TextStyle(
                        fontSize: 11,
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.3),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: 4,
            ),
            BoxShadow(
              // ignore: deprecated_member_use
              color: const Color(0xFF1B8B6A).withOpacity(0.6),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white,
              child: const Icon(
                Icons.favorite_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          // ignore: deprecated_member_use
          color: Colors.white.withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }
}
