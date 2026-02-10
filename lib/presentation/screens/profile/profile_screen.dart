import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:are_you_okay/routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../../provider/auth_provider.dart';

/// Profile Screen
/// Displays user profile information
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: authState.maybeWhen(
        loading: () => const Center(child: CircularProgressIndicator()),
        authenticated: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user.profilePicture != null
                            ? NetworkImage(user.profilePicture!)
                            : null,
                        child: user.profilePicture == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              // TODO: Change profile picture
                            },
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Phone
                Text(
                  user.phoneNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Info Cards
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  title: 'ইমেইল',
                  value: user.email ?? 'যোগ হয়নি',
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'জন্ম তারিখ',
                  value: user.dateOfBirth != null
                      ? '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}'
                      : 'যোগ হয়নি',
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'ঠিকানা',
                  value: user.address ?? 'যোগ হয়নি',
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.bloodtype,
                  title: 'রক্তের গ্রুপ',
                  value: user.bloodGroup ?? 'যোগ হয়নি',
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.timer_outlined,
                  title: 'চেক-ইন ইন্টারভাল',
                  value: '${user.checkinInterval} ঘণ্টা',
                ),
                const SizedBox(height: 32),

                // Edit Profile Button
                CustomButton(
                  text: 'প্রোফাইল সম্পাদনা করুন',
                  onPressed: () {
                    Navigator.pushNamed(context, '/edit-profile');
                  },
                  icon: Icons.edit,
                ),
                const SizedBox(height: 16),

                // Logout Button
                CustomButton(
                  text: 'লগ আউট',
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  isOutlined: true,
                  icon: Icons.logout,
                ),
              ],
            ),
          );
        },
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text('ত্রুটি: $message'),
            ],
          ),
        ),
        unauthenticated: () => const Center(
          child: Text('অনুগ্রহ করে লগইন করুন'),
        ),
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
