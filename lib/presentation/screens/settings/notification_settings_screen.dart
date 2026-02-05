import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _smsAlerts = true;
  bool _wellnessReminders = true;
  bool _emergencyAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বিজ্ঞপ্তি সেটিংস'),
      ),
      body: ListView(
        children: [
          _buildSwitchTile(
            title: 'পুশ বিজ্ঞপ্তি',
            subtitle: 'অ্যাপের মাধ্যমে সরাসরি আপডেট পান',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _buildSwitchTile(
            title: 'SMS অ্যালার্ট',
            subtitle: 'জরুরি অবস্থায় SMS পাঠাতে অনুমতি দিন',
            value: _smsAlerts,
            onChanged: (v) => setState(() => _smsAlerts = v),
          ),
          _buildSwitchTile(
            title: 'ওয়েলনেস রিমাইন্ডার',
            subtitle: 'প্রতিদিন সকালে আপনার খোঁজ নেওয়ার জন্য',
            value: _wellnessReminders,
            onChanged: (v) => setState(() => _wellnessReminders = v),
          ),
          _buildSwitchTile(
            title: 'জরুরি অ্যালার্ট',
            subtitle: 'গুরুত্বপূর্ণ সুরক্ষা অ্যালার্ট গ্রহণ করুন',
            value: _emergencyAlerts,
            onChanged: (v) => setState(() => _emergencyAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
