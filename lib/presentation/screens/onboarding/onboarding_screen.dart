import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_router.dart';
import '../../../services/shared_prefs_service.dart';
import '../../widgets/custom_button.dart';
import '../../../core/localization/app_strings.dart';
import '../../../provider/language_provider.dart';

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
        image: 'assets/images/onboarding_1.png', // Placeholder
        icon: Icons.shield_moon_rounded,
      ),
      _OnboardingItem(
        title: s.onbTitle2,
        description: s.onbDesc2,
        image: 'assets/images/onboarding_2.png',
        icon: Icons.location_on_rounded,
      ),
      _OnboardingItem(
        title: s.onbTitle3,
        description: s.onbDesc3,
        image: 'assets/images/onboarding_3.png',
        icon: Icons.emergency_rounded,
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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          // Background Blob
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: AppColors.primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        s.isBangla ? 'এড়িয়ে যান' : 'Skip',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'HindSiliguri',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPageItem(items[index]);
                    },
                  ),
                ),

                // Bottom Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Indicators
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: items.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: AppColors.primary,
                          // ignore: deprecated_member_use
                          dotColor: AppColors.primary.withOpacity(0.2),
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Next / Start Button
                      CustomButton(
                        text: _currentPage == items.length - 1
                            ? s.onbGetStarted
                            : s.onbNext,
                        onPressed: () {
                          if (_currentPage < items.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
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
        ],
      ),
    );
  }

  Widget _buildPageItem(_OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Placeholder (simulating illustration)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 48),

          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'HindSiliguri',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontFamily: 'HindSiliguri',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Request permissions
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

class _OnboardingItem {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  _OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}
