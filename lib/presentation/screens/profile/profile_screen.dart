import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/checkin_provider.dart';
import '../../../provider/language_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../routes/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    String name = s.profileDefaultUser;
    String email = '';
    String phone = '';
    String address = '';
    String bloodGroup = '';
    String profilePicture = '';

    if (authState is AuthAuthenticated) {
      name = authState.user.name;
      email = authState.user.email;
      phone = authState.user.phone ?? '';
      address = authState.user.address ?? '';
      bloodGroup = authState.user.bloodGroup ?? '';
      profilePicture = authState.user.profilePicture ?? '';
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
                              // ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                // ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.4),
                                width: 3,
                              ),
                              image: profilePicture.isNotEmpty
                                  ? DecorationImage(
                                      image: profilePicture
                                              .startsWith('data:image')
                                          ? MemoryImage(base64Decode(
                                              profilePicture
                                                  .split(',')
                                                  .last)) as ImageProvider
                                          : NetworkImage(profilePicture),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profilePicture.isEmpty
                                ? Center(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  )
                                : null,
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
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        if (address.isNotEmpty || bloodGroup.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (bloodGroup.isNotEmpty) ...[
                                  const Icon(Icons.bloodtype,
                                      color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    bloodGroup,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  if (address.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                        width: 1,
                                        height: 12,
                                        color: Colors.white.withValues(alpha: 0.2)),
                                    const SizedBox(width: 8),
                                  ]
                                ],
                                if (address.isNotEmpty) ...[
                                  const Icon(Icons.location_on,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      address,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontFamily: 'HindSiliguri'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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
                    _buildStatsRow(context, isDark, ref, s),
                    const SizedBox(height: 24),

                    // Info Card
                    _buildInfoCard(context, isDark, name, email, phone, address,
                        bloodGroup, s),
                    const SizedBox(height: 16),

                    // Quick Settings
                    _buildQuickSettings(context, isDark, s),
                    const SizedBox(height: 32),

                    // Delete Account Button
                    _buildDeleteAccountButton(context, s),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, bool isDark, WidgetRef ref, AppStrings s) {
    final status = ref.watch(checkinStatusProvider);
    final historyAsync = ref.watch(checkinHistoryFromBackendProvider);

    // Get total check-ins and active days from backend data
    int totalCheckIns = 0;
    int activeDays = 0;
    historyAsync.whenData((checkins) {
      totalCheckIns = checkins.length;
      final uniqueDays = <String>{};
      for (final c in checkins) {
        final ts = c['checkInTime'] ?? c['timestamp'];
        if (ts != null) {
          final dt = DateTime.tryParse(ts.toString());
          if (dt != null) uniqueDays.add("${dt.year}-${dt.month}-${dt.day}");
        }
      }
      activeDays = uniqueDays.length;
    });

    return Row(
      children: [
        _buildStatCard(
          context: context,
          icon: Icons.check_circle,
          value: totalCheckIns.toString(),
          label: s.profileTotalCheckins,
          color: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context: context,
          icon: Icons.local_fire_department,
          value: status.streak.toString(),
          label: s.statStreak,
          color: const Color(0xFFFF9800),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context: context,
          icon: Icons.calendar_today,
          value: activeDays.toString(),
          label: s.profileActiveDays,
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
    String address,
    String bloodGroup,
    AppStrings s,
  ) {
    return Container(
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.person_outline,
            s.contactsName,
            name,
          ),
          const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
          _buildInfoRow(
            context,
            Icons.email_outlined,
            s.contactsEmail,
            email,
          ),
          if (phone.isNotEmpty) ...[
            const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
            _buildInfoRow(
              context,
              Icons.phone_outlined,
              s.contactsPhone,
              phone,
            ),
          ],
          if (address.isNotEmpty) ...[
            const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
            _buildInfoRow(
              context,
              Icons.location_on_outlined,
              s.profileAddress,
              address,
            ),
          ],
          if (bloodGroup.isNotEmpty) ...[
            const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
            _buildInfoRow(
              context,
              Icons.bloodtype_outlined,
              s.profileBloodGroup,
              bloodGroup,
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
              // ignore: deprecated_member_use
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
                  style: const TextStyle(
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

  Widget _buildQuickSettings(BuildContext context, bool isDark, AppStrings s) {
    return Container(
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(
        children: [
          _buildActionTile(
            context: context,
            icon: Icons.settings,
            color: const Color(0xFF607D8B),
            title: s.navSettings,
            onTap: () => context.push(Routes.settings),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
          _buildActionTile(
            context: context,
            icon: Icons.contacts,
            color: const Color(0xFF009688),
            title: s.contactsTitle,
            onTap: () => context.push(Routes.contacts),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5),
          _buildActionTile(
            context: context,
            icon: Icons.history,
            color: const Color(0xFFFF9800),
            title: s.chHistoryTitle,
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
                // ignore: deprecated_member_use
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
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

  Widget _buildDeleteAccountButton(BuildContext context, AppStrings s) {
    return Center(
      child: TextButton.icon(
        onPressed: _isDeleting ? null : _showDeleteConfirmation,
        icon: _isDeleting 
            ? const SizedBox(
                width: 18, 
                height: 18, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)
              )
            : const Icon(Icons.delete_forever, color: Colors.redAccent),
        label: Text(
          s.settingsDeleteAccount,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontFamily: 'HindSiliguri',
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.settingsDeleteAccountConfirm,
            style: const TextStyle(
                fontFamily: 'HindSiliguri', fontWeight: FontWeight.bold)),
        content: Text(s.settingsDeleteAccountWarning,
            style: const TextStyle(fontFamily: 'HindSiliguri')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.dialogCancel,
                style: const TextStyle(fontFamily: 'HindSiliguri')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(s.confirm,
                style: const TextStyle(fontFamily: 'HindSiliguri')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final s = ref.read(stringsProvider);
    setState(() => _isDeleting = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.isBangla
                ? 'আপনার অ্যাকাউন্টটি মুছে ফেলা হয়েছে'
                : 'Your account has been deleted'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
