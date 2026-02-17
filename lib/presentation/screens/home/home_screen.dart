import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/checkin_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../../services/shake_detector_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;
  Timer? _countdownTimer;
  int _selectedMood = -1;
  int _bottomNavIndex = 0;

  // Countdown
  Duration _timeRemaining = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();

    // Pulse animation for check-in button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ring rotation animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _ringAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_ringController);

    // Initialize Shake Detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shakeDetectorProvider).startListening(() {
        if (mounted) {
           // Show snackbar or visual feedback before navigating? 
           // For now, direct navigation to SOS screen (which has countdown)
           context.push(Routes.sos);
        }
      });
    });

    // Start countdown timer
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _countdownTimer?.cancel();
    ref.read(shakeDetectorProvider).stopListening();
    super.dispose();
  }

  double get _urgencyPercent {
    final total = const Duration(hours: 24).inSeconds;
    final remaining = _timeRemaining.inSeconds;
    return 1.0 - (remaining / total);
  }

  Color get _urgencyColor {
    if (_urgencyPercent < 0.5) return AppColors.success;
    if (_urgencyPercent < 0.75) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final checkinState = ref.watch(checkinProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    String userName = 'ব্যবহারকারী';
    if (authState is AuthAuthenticated) {
      userName = authState.user.name;
    }

    return Scaffold(
      body: Container(
        decoration: isDark
            ? AppDecorations.subtleGradientDark()
            : AppDecorations.subtleGradientLight(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ==================== Header ====================
                  _buildHeader(userName, isDark),
                  const SizedBox(height: 28),

                  // ==================== Check-in Button ====================
                  _buildCheckinButton(checkinState, isDark),
                  const SizedBox(height: 12),

                  // ==================== Countdown Timer ====================
                  _buildCountdownTimer(isDark),
                  const SizedBox(height: 24),

                  // ==================== Mood Selector ====================
                  _buildMoodSelector(isDark),
                  const SizedBox(height: 24),

                  // ==================== Quick Actions ====================
                  Text(
                    'দ্রুত অ্যাকশন',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(isDark),
                  const SizedBox(height: 24),

                  // ==================== Safety Stats ====================
                  _buildSafetyStats(isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ==================== Header ====================
  Widget _buildHeader(String name, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildHeaderIcon(Icons.notifications_outlined, () {
              // TODO: Notification center
            }),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push(Routes.profile),
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    boxShadow: AppDecorations.coloredShadow(
                      AppColors.primary,
                      opacity: 0.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }

  // ==================== Check-in Button ====================
  Widget _buildCheckinButton(CheckInState state, bool isDark) {
    final isLoading = state is CheckInLoading;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isLoading ? 1.0 : _pulseAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: isLoading ? null : _performCheckin,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppDecorations.coloredShadow(
                _urgencyColor,
                opacity: 0.35,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated ring
                AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(180, 180),
                      painter: _SafetyRingPainter(
                        progress: 1.0 - _urgencyPercent,
                        color: _urgencyColor,
                        rotation: _ringAnimation.value,
                      ),
                    );
                  },
                ),
                // Inner circle
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _urgencyColor,
                        _urgencyColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 36,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'চেক-ইন',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'HindSiliguri',
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Countdown Timer ====================
  Widget _buildCountdownTimer(bool isDark) {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    return Center(
      child: Column(
        children: [
          StatusBadge(
            type: _urgencyPercent < 0.5
                ? StatusType.safe
                : _urgencyPercent < 0.75
                    ? StatusType.warning
                    : StatusType.danger,
            label: _urgencyPercent < 0.5
                ? 'নিরাপদ'
                : _urgencyPercent < 0.75
                    ? 'চেক-ইন প্রয়োজন'
                    : 'জরুরি চেক-ইন',
          ),
          const SizedBox(height: 12),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
              color: _urgencyColor,
              fontFamily: 'HindSiliguri',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'পরবর্তী চেক-ইনের বাকি সময়',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ==================== Mood Selector ====================
  Widget _buildMoodSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আজ আপনার মেজাজ কেমন?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              AppConstants.moodEmojis.length,
              (index) => GestureDetector(
                onTap: () => setState(() => _selectedMood = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedMood == index
                        ? AppColors.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedMood == index
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppConstants.moodEmojis[index],
                        style: TextStyle(
                          fontSize: _selectedMood == index ? 28 : 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.moodLabels[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'HindSiliguri',
                          fontWeight: _selectedMood == index
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedMood == index
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Quick Actions ====================
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      _QuickAction(
        icon: Icons.sos,
        label: 'জরুরি SOS',
        color: const Color(0xFFF44336),
        gradient: [const Color(0xFFF44336), const Color(0xFFE53935)],
        route: Routes.sos,
        heroTag: 'sos_icon',
      ),
      _QuickAction(
        icon: Icons.smart_toy_outlined,
        label: 'AI চ্যাট',
        color: const Color(0xFF6C63FF),
        gradient: [const Color(0xFF6C63FF), const Color(0xFF5A52D5)],
        route: Routes.aiChat,
      ),
      _QuickAction(
        icon: Icons.contacts_outlined,
        label: 'যোগাযোগ',
        color: const Color(0xFF00BCD4),
        gradient: [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
        route: Routes.contacts,
      ),
      _QuickAction(
        icon: Icons.phone_callback_outlined,
        label: 'ফেক কল',
        color: const Color(0xFFFF9800),
        gradient: [const Color(0xFFFF9800), const Color(0xFFF57C00)],
        route: Routes.fakeCall,
      ),
      _QuickAction(
        icon: Icons.public,
        label: 'ভূমিকম্প',
        color: const Color(0xFF795548),
        gradient: [const Color(0xFF795548), const Color(0xFF5D4037)],
        route: Routes.earthquake,
      ),
      _QuickAction(
        icon: Icons.history,
        label: 'ইতিহাস',
        color: const Color(0xFF009688),
        gradient: [const Color(0xFF009688), const Color(0xFF00796B)],
        route: Routes.history,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: () => context.push(action.route),
          child: Container(
            decoration: AppDecorations.cardDecoration(
              context: context,
              borderRadius: 18,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: action.gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppDecorations.coloredShadow(
                      action.color,
                      opacity: 0.25,
                    ),
                  ),
                  child: action.heroTag != null
                      ? Hero(
                          tag: action.heroTag!,
                          child: Icon(
                            action.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : Icon(
                          action.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HindSiliguri',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== Safety Stats ====================
  Widget _buildSafetyStats(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'নিরাপত্তা পরিসংখ্যান',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                value: '0',
                label: 'চেক-ইন',
                color: AppColors.success,
              ),
              _buildStatItem(
                icon: Icons.local_fire_department,
                value: '0',
                label: 'স্ট্রিক',
                color: const Color(0xFFFF9800),
              ),
              _buildStatItem(
                icon: Icons.shield,
                value: '0',
                label: 'নিরাপদ দিন',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'HindSiliguri',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontFamily: 'HindSiliguri',
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Bottom Navigation ====================
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'হোম'),
              _buildNavItem(1, Icons.history_rounded, 'ইতিহাস'),
              _buildNavItem(2, Icons.contacts_rounded, 'যোগাযোগ'),
              _buildNavItem(3, Icons.settings_rounded, 'সেটিংস'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _bottomNavIndex = index);
        switch (index) {
          case 0:
            break; // Already on home
          case 1:
            context.push(Routes.history);
            break;
          case 2:
            context.push(Routes.contacts);
            break;
          case 3:
            context.push(Routes.settings);
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontFamily: 'HindSiliguri',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Helpers ====================
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'সুপ্রভাত 🌅';
    if (hour < 17) return 'শুভ দুপুর ☀️';
    if (hour < 20) return 'শুভ সন্ধ্যা 🌆';
    return 'শুভ রাত্রি 🌙';
  }

  void _performCheckin() {
    String? notes;
    if (_selectedMood != -1 && _selectedMood < AppConstants.moodLabels.length) {
      final moodLabel = AppConstants.moodLabels[_selectedMood];
      notes = 'Mood: $moodLabel';
    }

    ref.read(checkinProvider.notifier).performCheckIn(
      method: 'button',
      notes: notes,
    );
    
    setState(() {
      _timeRemaining = const Duration(hours: 24);
      _selectedMood = -1; // Reset mood
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'চেক-ইন সফল হয়েছে!',
          style: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// ==================== Models ====================
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final String route;

  final String? heroTag;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.route,
    this.heroTag,
  });
}

// ==================== Safety Ring Painter ====================
class _SafetyRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double rotation;

  _SafetyRingPainter({
    required this.progress,
    required this.color,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SafetyRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      rotation != oldDelegate.rotation;
}