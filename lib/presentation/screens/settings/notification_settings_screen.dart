import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../provider/language_provider.dart';
import '../../../provider/settings_provider.dart';

/// Notification Settings Screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> with RestorationMixin {
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;
  bool? _pushNotifications;
  bool? _smsAlerts;
  bool? _wellnessReminders;
  bool? _emergencyAlerts;
  bool _isSaving = false;

  @override
  String? get restorationId => 'notification_settings_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_scrollOffset, 'scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final pushNotifications =
        _pushNotifications ?? settings.notificationsEnabled;
    final smsAlerts = _smsAlerts ?? settings.smsAlerts;
    final wellnessReminders = _wellnessReminders ?? settings.wellnessReminders;
    final emergencyAlerts = _emergencyAlerts ?? settings.emergencyAlerts;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifSettingsTitle),
      ),
      body: ListView(
        key: const PageStorageKey('notification_settings_scroll'),
        controller: _scrollController,
        children: [
          _buildSwitchTile(
            title: s.notifPushTitle,
            subtitle: s.notifPushSubtitle,
            value: pushNotifications,
            onChanged: (v) => _savePreferences(pushNotifications: v),
          ),
          _buildSwitchTile(
            title: s.notifSmsTitle,
            subtitle: s.notifSmsSubtitle,
            value: smsAlerts,
            onChanged:
                emergencyAlerts ? (v) => _savePreferences(smsAlerts: v) : null,
          ),
          _buildSwitchTile(
            title: s.notifWellnessTitle,
            subtitle: s.notifWellnessSubtitle,
            value: wellnessReminders,
            onChanged: pushNotifications
                ? (v) => _savePreferences(wellnessReminders: v)
                : null,
          ),
          _buildSwitchTile(
            title: s.notifEmergencyAlertsTitle,
            subtitle: s.notifEmergencyAlertsSubtitle,
            value: emergencyAlerts,
            onChanged: (v) => _savePreferences(emergencyAlerts: v),
          ),
          if (_isSaving) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Future<void> _savePreferences({
    bool? pushNotifications,
    bool? smsAlerts,
    bool? wellnessReminders,
    bool? emergencyAlerts,
  }) async {
    setState(() {
      if (pushNotifications != null) _pushNotifications = pushNotifications;
      if (smsAlerts != null) _smsAlerts = smsAlerts;
      if (wellnessReminders != null) _wellnessReminders = wellnessReminders;
      if (emergencyAlerts != null) _emergencyAlerts = emergencyAlerts;
      _isSaving = true;
    });

    try {
      await ref.read(settingsProvider.notifier).setNotificationPreferences(
            pushNotifications: _pushNotifications,
            smsAlerts: _smsAlerts,
            wellnessReminders: _wellnessReminders,
            emergencyAlerts: _emergencyAlerts,
          );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
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
