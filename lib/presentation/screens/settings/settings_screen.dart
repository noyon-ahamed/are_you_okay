import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

/// Settings Screen
/// App settings and preferences
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'বাংলা';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('সাধারণ'),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'ভাষা',
            subtitle: _selectedLanguage,
            onTap: () {
              _showLanguageDialog();
            },
          ),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: 'ডার্ক মোড',
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(),

          _buildSectionHeader('বিজ্ঞপ্তি'),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'বিজ্ঞপ্তি',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.notification_important_outlined,
            title: 'বিজ্ঞপ্তি সেটিংস',
            onTap: () {
              Navigator.pushNamed(context, '/notification-settings');
            },
          ),
          const Divider(),

          _buildSectionHeader('গোপনীয়তা ও নিরাপত্তা'),
          _buildSettingsTile(
            icon: Icons.location_on_outlined,
            title: 'লোকেশন ট্র্যাকিং',
            trailing: Switch(
              value: _locationEnabled,
              onChanged: (value) {
                setState(() {
                  _locationEnabled = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.lock_outlined,
            title: 'পাসওয়ার্ড পরিবর্তন',
            onTap: () {
              // TODO: Navigate to change password
            },
          ),
          const Divider(),

          _buildSectionHeader('তথ্য'),
          _buildSettingsTile(
            icon: Icons.info_outlined,
            title: 'অ্যাপ সম্পর্কে',
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'গোপনীয়তা নীতি',
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'শর্তাবলী',
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'সাহায্য ও সহায়তা',
            onTap: () {
              // TODO: Show help
            },
          ),
          const Divider(),

          _buildSectionHeader('বিপজ্জনক অঞ্চল'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: 'অ্যাকাউন্ট মুছুন',
              onPressed: () {
                _showDeleteAccountDialog();
              },
              backgroundColor: AppColors.danger,
              icon: Icons.delete_forever,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : null),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ভাষা নির্বাচন করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('বাংলা'),
              value: 'বাংলা',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'ভালো আছেন কি?',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const Text('আপনার নিরাপত্তা, আমাদের দায়িত্ব'),
        const SizedBox(height: 16),
        const Text(
          'এই অ্যাপটি বাংলাদেশের মানুষের নিরাপত্তার জন্য তৈরি করা হয়েছে। '
          'নিয়মিত চেক-ইন করে আপনার প্রিয়জনদের জানান যে আপনি ভালো আছেন।',
        ),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('অ্যাকাউন্ট মুছুন?'),
        content: const Text(
          'আপনি কি নিশ্চিত যে আপনি আপনার অ্যাকাউন্ট মুছতে চান? '
          'এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Delete account
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
  }
}
