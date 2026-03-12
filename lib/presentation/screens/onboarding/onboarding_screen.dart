import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../provider/language_provider.dart';
import '../../../routes/app_router.dart';
import '../../../services/shared_prefs_service.dart';
import '../../widgets/custom_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingItem> _getItems(AppStrings s) {
    return [
      _OnboardingItem(
        title: s.onbTitle1,
        description: s.onbDesc1,
        icon: Icons.favorite_rounded,
        accent: const Color(0xFFE8F5F0),
        stat: s.onbStatDailySafety,
      ),
      _OnboardingItem(
        title: s.onbTitle2,
        description: s.onbDesc2,
        icon: Icons.location_on_rounded,
        accent: const Color(0xFFFFF1E3),
        stat: s.onbStatRealtimeLocation,
      ),
      _OnboardingItem(
        title: s.onbTitle3,
        description: s.onbDesc3,
        icon: Icons.shield_rounded,
        accent: const Color(0xFFFFE8EB),
        stat: s.onbStatEmergencySupport,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final items = _getItems(s);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF7F6F2),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF0E1714),
                    Color(0xFF12231D),
                    Color(0xFF1A1715)
                  ]
                : const [
                    Color(0xFFF7F6F2),
                    Color(0xFFE9F4EF),
                    Color(0xFFFFF3EE)
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      s.onbSkip,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontFamily: 'HindSiliguri',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPageItem(context, items[index], isDark, s);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: items.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.primary,
                        dotColor: AppColors.primary.withValues(alpha: 0.18),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3.8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: _currentPage == items.length - 1
                          ? s.onbGetStarted
                          : s.onbNext,
                      onPressed: () {
                        if (_currentPage < items.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
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

  Widget _buildPageItem(
    BuildContext context,
    _OnboardingItem item,
    bool isDark,
    AppStrings s,
  ) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          _buildHeroCard(item, isDark, s),
          const SizedBox(height: 36),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              fontFamily: 'HindSiliguri',
              color: textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontFamily: 'HindSiliguri',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    item.stat,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeroCard(_OnboardingItem item, bool isDark, AppStrings s) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        item.accent,
                        item.accent.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 18,
                        bottom: 18,
                        child: Image.asset(
                          'assets/images/logo_padded.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 108,
                        bottom: 22,
                        child: Text(
                          s.onbSafetyOneTap,
                          style: const TextStyle(
                            fontFamily: 'HindSiliguri',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeatureStrip(
                  color: AppColors.primary,
                  label: s.onbFeatureCheckin,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureStrip(
                  color: AppColors.secondary,
                  label: s.onbFeatureAlerts,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    await [
      Permission.location,
      Permission.notification,
      Permission.microphone,
    ].request();

    await ref.read(sharedPrefsServiceProvider).setFirstLaunchComplete();

    if (mounted) {
      context.go(Routes.login);
    }
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.stat,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String stat;
}
