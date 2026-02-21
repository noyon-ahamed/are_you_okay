import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/checkin_provider.dart';
import '../../../routes/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String name = 'ব্যবহারকারী';
    String email = '';
    String phone = '';

    if (authState is AuthAuthenticated) {
      name = authState.user.name;
      email = authState.user.email;
      phone = authState.user.phone ?? '';
    }

    return Scaffold(
      body: Container(
        decoration: isDark
            ? AppDecorations.subtleGradientDark()
            : AppDecorations.subtleGradientLight(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ==================== App Bar ====================
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: AppDecorations.primaryGradientBg(),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar
                        Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'HindSiliguri',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push(Routes.editProfile),
                ),
              ],
            ),

            // ==================== Content ====================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Stats Row
                    _buildStatsRow(context, isDark, ref),
                    const SizedBox(height: 24),

                    // Info Card
                    _buildInfoCard(context, isDark, name, email, phone),
                    const SizedBox(height: 16),

                    // Quick Settings
                    _buildQuickSettings(context, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark, WidgetRef ref) {
    final checkins = ref.watch(checkinHistoryProvider);
    final status = ref.watch(checkinStatusProvider);

    final activeDays = checkins.map((c) => "${c.timestamp.year}-${c.timestamp.month}-${c.timestamp.day}").toSet().length;

    return Row(
      children: [
        _buildStatCard(
          context: context,
          icon: Icons.check_circle,
          value: checkins.length.toString(),
          label: 'মোট চেক-ইন',
          color: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context: context,
          icon: Icons.local_fire_department,
          value: status.streak.toString(),
          label: 'স্ট্রিক',
          color: const Color(0xFFFF9800),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context: context,
          icon: Icons.calendar_today,
          value: activeDays.toString(),
          label: 'সক্রিয় দিন',
          color: AppColors.primary,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.cardDecoration(
          context: context,
          borderRadius: 16,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'HindSiliguri',
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'HindSiliguri',
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isDark,
    String name,
    String email,
    String phone,
  ) {
    return Container(
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.person_outline,
            'নাম',
            name,
          ),
          Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
          _buildInfoRow(
            context,
            Icons.email_outlined,
            'ইমেইল',
            email,
          ),
          if (phone.isNotEmpty) ...[
            Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
            _buildInfoRow(
              context,
              Icons.phone_outlined,
              'ফোন',
              phone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'HindSiliguri',
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'HindSiliguri',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettings(BuildContext context, bool isDark) {
    return Container(
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(
        children: [
          _buildActionTile(
            context: context,
            icon: Icons.settings,
            color: const Color(0xFF607D8B),
            title: 'সেটিংস',
            onTap: () => context.push(Routes.settings),
          ),
          Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
          _buildActionTile(
            context: context,
            icon: Icons.contacts,
            color: const Color(0xFF009688),
            title: 'জরুরি যোগাযোগ',
            onTap: () => context.push(Routes.contacts),
          ),
          Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
          _buildActionTile(
            context: context,
            icon: Icons.history,
            color: const Color(0xFFFF9800),
            title: 'চেক-ইন ইতিহাস',
            onTap: () => context.push(Routes.history),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}
