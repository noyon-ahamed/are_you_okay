import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/settings_provider.dart';
import '../../../provider/checkin_provider.dart';
import '../../../routes/app_router.dart';
import '../../../services/api/checkin_api_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final statusData = ref.watch(checkinStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // ==================== Appearance ====================
          _buildSectionHeader('ডিজাইন'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildSwitchTile(
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF6C63FF),
              title: 'ডার্ক মোড',
              subtitle: 'অন্ধকার থিম সক্রিয় করুন',
              value: settings.themeIsDark,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setDarkMode(val);
              },
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF00BCD4),
              title: 'ভাষা',
              subtitle: settings.language == 'bn' ? 'বাংলা' : 'English',
              onTap: () => _showLanguageDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Safety ====================
          _buildSectionHeader('নিরাপত্তা'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.local_fire_department,
              iconColor: Colors.deepOrange,
              title: 'বর্তমান স্ট্রিক',
              subtitle: '${statusData.streak} দিন',
              onTap: () {},
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.timer_rounded,
              iconColor: AppColors.primary,
              title: 'চেক-ইন ইন্টারভাল',
              subtitle: 'প্রতি ${settings.checkinIntervalHours} ঘণ্টা পর',
              onTap: () => _showIntervalDialog(),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFFFF9800),
              title: 'নোটিফিকেশন',
              subtitle: 'চেক-ইন রিমাইন্ডার পাঠান',
              value: settings.notificationsEnabled,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleNotifications();
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF4CAF50),
              title: 'লোকেশন',
              subtitle: 'চেক-ইনে লোকেশন সংযুক্ত করুন',
              value: settings.locationEnabled,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleLocation();
              },
            ),
            // _buildDivider(),
            // _buildSwitchTile(
            //   icon: Icons.fingerprint_rounded,
            //   iconColor: const Color(0xFF9C27B0),
            //   title: 'বায়োমেট্রিক লক',
            //   subtitle: 'অ্যাপ খুলতে ফিঙ্গারপ্রিন্ট ব্যবহার করুন',
            //   value: settings.biometricEnabled,
            //   onChanged: (_) {
            //     ref.read(settingsProvider.notifier).toggleBiometric();
            //   },
            // ),
          ]),

          const SizedBox(height: 24),

          // ==================== Account ====================
          _buildSectionHeader('অ্যাকাউন্ট'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF2196F3),
              title: 'প্রোফাইল',
              subtitle: 'প্রোফাইল তথ্য সম্পাদনা',
              onTap: () => context.push(Routes.profile),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.contacts_rounded,
              iconColor: const Color(0xFF009688),
              title: 'জরুরি যোগাযোগ',
              subtitle: 'যোগাযোগ পরিচালনা',
              onTap: () => context.push(Routes.contacts),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Data ====================
          _buildSectionHeader('ডেটা'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.download_rounded,
              iconColor: const Color(0xFF795548),
              title: 'ডেটা এক্সপোর্ট',
              subtitle: 'চেক-ইন ইতিহাস ডাউনলোড',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ডেটা এক্সপোর্ট শীঘ্রই আসছে...',
                      style: TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.error,
              title: 'ক্যাশ পরিষ্কার',
              subtitle: 'স্থানীয় ডেটা পরিষ্কার করুন',
              onTap: () => _showClearDataDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== About ====================
          _buildSectionHeader('সম্পর্কে'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF607D8B),
              title: 'অ্যাপ সম্পর্কে',
              subtitle: 'ভার্সন 2.0.0',
              onTap: () {},
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF78909C),
              title: 'গোপনীয়তা নীতি',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Logout ====================
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'লগআউট',
                style: TextStyle(
                  color: AppColors.error,
                  fontFamily: 'HindSiliguri',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ==================== Builders ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    )),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      )),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )),
                ],
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

  Widget _buildSliderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        )),
                    Text(subtitle,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider.adaptive(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            label: '${value.round()} ঘণ্টা',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==================== Dialogs ====================

  void _showLanguageDialog() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ভাষা নির্বাচন',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            _buildLanguageOption('বাংলা', 'bn', settings.language == 'bn'),
            _buildLanguageOption('English', 'en', settings.language == 'en'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code, bool isSelected) {
    return ListTile(
      title: Text(label, style: TextStyle(fontFamily: 'HindSiliguri')),
      leading: Radio<String>(
        value: code,
        groupValue: isSelected ? code : null,
        onChanged: (val) {
          ref.read(settingsProvider.notifier).setLanguage(code);
          Navigator.pop(context);
        },
        activeColor: AppColors.primary,
      ),
      onTap: () {
        ref.read(settingsProvider.notifier).setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ক্যাশ পরিষ্কার',
            style: TextStyle(fontFamily: 'HindSiliguri')),
        content: Text(
          'আপনি কি নিশ্চিত? স্থানীয় ডেটা মুছে যাবে।',
          style: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল',
                style: TextStyle(fontFamily: 'HindSiliguri')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('ক্যাশ পরিষ্কার হয়েছে',
                        style: TextStyle(fontFamily: 'HindSiliguri'))),
              );
            },
            child: Text('পরিষ্কার করুন',
                style: TextStyle(
                    fontFamily: 'HindSiliguri', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('লগআউট',
            style: TextStyle(fontFamily: 'HindSiliguri')),
        content: Text(
          'আপনি কি লগআউট করতে চান?',
          style: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল',
                style: TextStyle(fontFamily: 'HindSiliguri')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(Routes.login);
            },
            child: Text('লগআউট',
                style: TextStyle(
                    fontFamily: 'HindSiliguri', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showIntervalDialog() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('চেক-ইন সময়সীমা',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            _buildIntervalOption('২৪ ঘণ্টা (দৈনিক)', 24, settings.checkinIntervalHours == 24),
            _buildIntervalOption('৪৮ ঘণ্টা (২ দিন)', 48, settings.checkinIntervalHours == 48),
            _buildIntervalOption('৭২ ঘণ্টা (৩ দিন)', 72, settings.checkinIntervalHours == 72),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalOption(String label, int value, bool isSelected) {
    return ListTile(
      title: Text(label, style: TextStyle(fontFamily: 'HindSiliguri')),
      leading: Radio<int>(
        value: value,
        groupValue: isSelected ? value : null,
        onChanged: (val) => _updateInterval(value),
        activeColor: AppColors.primary,
      ),
      onTap: () => _updateInterval(value),
    );
  }

  void _updateInterval(int value) async {
    Navigator.pop(context);
    try {
      // Sync with local provider
      ref.read(settingsProvider.notifier).setCheckinInterval(value);
      // Sync with backend API
      await CheckinApiService().setCheckInInterval(value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইন্টারভাল আপডেট হয়েছে ✓', style: TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to set interval: \$e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইন্টারভাল আপডেট ব্যর্থ হয়েছে', style: TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
