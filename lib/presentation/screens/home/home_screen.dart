import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../routes/app_router.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/checkin_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _performCheckIn() async {
    HapticFeedback.mediumImpact();

    await ref.read(checkinProvider.notifier).performCheckIn();

    if (mounted) {
      final state = ref.read(checkinProvider);
      state.maybeWhen(
        success: (_) => _showSuccessDialog(),
        error: (message) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $message'), backgroundColor: AppColors.danger),
        ),
        orElse: () {},
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'চেক-ইন সফল!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'আপনি এখন নিরাপদ। আপনার প্রিয়জনদের আপডেট জানানো হয়েছে।',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ঠিক আছে'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = ref.watch(currentUserProvider);
    final hoursLeft = ref.watch(hoursUntilNextCheckinProvider) ?? 24;
    final lastCheckin = ref.watch(lastCheckinProvider);

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryContainer,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(user?.name ?? 'ব্যবহারকারী'),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'স্বাগতম, ${user?.name ?? 'বন্ধু'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppConstants.appTaglineBangla,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              _buildCheckInButton(hoursLeft),

              const SizedBox(height: 24),

              _buildTimeRemaining(hoursLeft),

              const SizedBox(height: 16),

              _buildLastCheckIn(lastCheckin?.timestamp),

              const Spacer(),

              _buildQuickActions(),

              const BannerAdWidget(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar(String name) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.push(Routes.profile),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Open notification center
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton(int hoursLeft) {
    return GestureDetector(
      onTap: _performCheckIn,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            gradient: _getButtonGradient(hoursLeft),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getButtonColor(hoursLeft).withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              const Text(
                'আমি ভালো আছি',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getButtonColor(int hoursLeft) {
    if (hoursLeft > 6) return AppColors.success;
    if (hoursLeft > 2) return AppColors.warning;
    return AppColors.danger;
  }

  Gradient _getButtonGradient(int hoursLeft) {
    if (hoursLeft > 6) {
      return const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
      );
    }
    if (hoursLeft > 2) {
      return const LinearGradient(
        colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFC62828), Color(0xFFF44336)],
    );
  }

  Widget _buildTimeRemaining(int hoursLeft) {
    final color = _getButtonColor(hoursLeft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'বাকি আছে: $hoursLeft ঘণ্টা',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastCheckIn(DateTime? lastTime) {
    final formattedTime = lastTime != null
        ? DateFormat('MMM dd, hh:mm a', 'bn').format(lastTime)
        : 'এখনও হয়নি';

    return Text(
      'সর্বশেষ চেক-ইন: $formattedTime',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionCard(
            icon: Icons.history,
            label: 'ইতিহাস',
            onTap: () => context.push(Routes.history),
          ),
          const SizedBox(width: 12),
          _buildActionCard(
            icon: Icons.people,
            label: 'যোগাযোগ',
            onTap: () => context.push(Routes.contacts),
          ),
          const SizedBox(width: 12),
          _buildActionCard(
            icon: Icons.warning,
            label: 'SOS',
            onTap: () => context.push(Routes.sos),
            isEmergency: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEmergency
                ? AppColors.danger.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmergency ? AppColors.danger : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isEmergency ? AppColors.danger : AppColors.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isEmergency ? AppColors.danger : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.push(Routes.contacts);
            break;
          case 2:
            context.push(Routes.profile);
            break;
          case 3:
            context.push(Routes.settings);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'হোম',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'কন্টাক্ট',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'প্রোফাইল',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'সেটিংস',
        ),
      ],
    );
  }
}