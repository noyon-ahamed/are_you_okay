import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../provider/language_provider.dart';

/// Notification Settings Screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _smsAlerts = true;
  bool _wellnessReminders = true;
  bool _emergencyAlerts = true;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifSettingsTitle),
      ),
      body: ListView(
        children: [
          _buildSwitchTile(
            title: s.notifPushTitle,
            subtitle: s.notifPushSubtitle,
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _buildSwitchTile(
            title: s.notifSmsTitle,
            subtitle: s.notifSmsSubtitle,
            value: _smsAlerts,
            onChanged: (v) => setState(() => _smsAlerts = v),
          ),
          _buildSwitchTile(
            title: s.notifWellnessTitle,
            subtitle: s.notifWellnessSubtitle,
            value: _wellnessReminders,
            onChanged: (v) => setState(() => _wellnessReminders = v),
          ),
          _buildSwitchTile(
            title: s.notifEmergencyAlertsTitle,
            subtitle: s.notifEmergencyAlertsSubtitle,
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
      activeThumbColor: AppColors.primary,
    );
  }
}
