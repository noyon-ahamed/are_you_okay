import 'package:flutter/foundation.dart';

import '../routes/app_router.dart';
import 'api/notification_api_service.dart';
import 'auth/token_storage_service.dart';
import 'local_notification_history_service.dart';
import 'notification_navigation_service.dart';
import 'notification_service.dart';

class NotificationSyncService {
  NotificationSyncService._internal();

  static final NotificationSyncService _instance =
      NotificationSyncService._internal();

  factory NotificationSyncService() => _instance;

  static const Duration _minimumSyncGap = Duration(seconds: 15);

  final LocalNotificationHistoryService _historyService =
      LocalNotificationHistoryService();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final NotificationApiService _notificationApiService =
      NotificationApiService();

  Future<int>? _syncInFlight;
  DateTime? _lastSyncAt;

  Future<int> syncMissedNotifications({
    bool surfaceLocally = true,
    bool force = false,
  }) async {
    final token = await TokenStorageService.getToken();
    if (token == null || token.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    if (!force &&
        _lastSyncAt != null &&
        now.difference(_lastSyncAt!) < _minimumSyncGap) {
      return 0;
    }

    if (_syncInFlight != null) {
      return _syncInFlight!;
    }

    _lastSyncAt = now;
    final future = _performSync(surfaceLocally: surfaceLocally);
    _syncInFlight = future;

    try {
      return await future;
    } finally {
      _syncInFlight = null;
    }
  }

  Future<int> _performSync({required bool surfaceLocally}) async {
    final latestCreatedAt = await _historyService.getLatestRemoteCreatedAt();
    final data = await _notificationApiService.getNotifications(
      latestCreatedAt: latestCreatedAt,
    );

    final remoteNotifications = (data['notifications'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (remoteNotifications.isNotEmpty) {
      await _historyService.cacheRemoteNotifications(remoteNotifications);
    }

    var surfacedCount = 0;
    if (surfaceLocally) {
      final pendingNotifications =
          await _historyService.getPendingRemoteNotificationsForSurfacing();
      if (pendingNotifications.isNotEmpty) {
        surfacedCount = await _surfaceMissedNotifications(pendingNotifications);
      }
    }

    await _historyService.setLatestRemoteCreatedAt(
      data['sync']?['latestCreatedAt']?.toString(),
    );

    return surfacedCount;
  }

  Future<int> _surfaceMissedNotifications(
    List<Map<String, dynamic>> remoteNotifications,
  ) async {
    await _localNotificationService.initialize(
      onNotificationTap: NotificationNavigationService.handlePayload,
    );

    final unreadNotifications = remoteNotifications
        .where((item) => item['isRead'] != true)
        .toList()
      ..sort((a, b) => _parseCreatedAt(a).compareTo(_parseCreatedAt(b)));

    var surfacedCount = 0;
    for (final notification in unreadNotifications) {
      final id = _notificationId(notification);
      if (id.isEmpty) continue;

      final alreadyInLocalHistory =
          await _historyService.containsNotification(id);
      if (alreadyInLocalHistory) {
        continue;
      }

      final title = _notificationTitle(notification);
      final body = notification['body']?.toString() ?? '';
      if (title.isEmpty && body.isEmpty) {
        continue;
      }

      final payload = _notificationPayload(notification);
      final localNotificationId = _localIdFor(notification);

      try {
        final normalizedType = _normalizedType(notification);
        if (normalizedType == 'reminder') {
          await _localNotificationService.showCheckinReminder(
            id: localNotificationId,
            title: title,
            body: body,
            payload: payload,
          );
        } else {
          await _localNotificationService.showNotification(
            id: localNotificationId,
            title: title,
            body: body,
            payload: payload,
            channelId: _channelIdFor(notification),
          );
        }

        await _historyService.saveNotification({
          ...notification,
          '_id': id,
          'id': id,
          'payload': payload,
          'type': normalizedType,
          'source': 'server_sync',
          'notificationId': localNotificationId,
        });
        surfacedCount += 1;
      } catch (error, stackTrace) {
        debugPrint('Failed to surface synced notification $id: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return surfacedCount;
  }

  DateTime _parseCreatedAt(Map<String, dynamic> notification) {
    return DateTime.tryParse(notification['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _notificationId(Map<String, dynamic> notification) {
    return notification['_id']?.toString() ??
        notification['id']?.toString() ??
        '';
  }

  String _notificationTitle(Map<String, dynamic> notification) {
    return notification['title_en']?.toString() ??
        notification['title']?.toString() ??
        'Notification';
  }

  String _normalizedType(Map<String, dynamic> notification) {
    final type = notification['type']?.toString() ?? 'system_announcement';
    return type == 'checkin_reminder' ? 'reminder' : type;
  }

  String _channelIdFor(Map<String, dynamic> notification) {
    final type = _normalizedType(notification);
    if (type == 'reminder') {
      return 'checkin_reminders';
    }
    if (type == 'earthquake_alert') {
      final actionData = notification['actionData'];
      final params = actionData is Map
          ? Map<String, dynamic>.from(actionData['params'] as Map? ?? const {})
          : const <String, dynamic>{};
      final severity = params['severity']?.toString() ?? '';
      if (severity == 'siren') {
        return 'seismic_alerts';
      }
      if (severity == 'urgent' ||
          notification['priority']?.toString() == 'urgent' ||
          notification['priority']?.toString() == 'high') {
        return 'emergency_alerts';
      }
      return 'info_updates';
    }
    if (type == 'emergency_alert' ||
        notification['priority']?.toString() == 'urgent') {
      return 'emergency_alerts';
    }
    return 'info_updates';
  }

  int _localIdFor(Map<String, dynamic> notification) {
    final id = _notificationId(notification);
    if (id.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    return id.hashCode & 0x7fffffff;
  }

  String _notificationPayload(Map<String, dynamic> notification) {
    final existingPayload = notification['payload']?.toString();
    if (existingPayload != null && existingPayload.isNotEmpty) {
      return existingPayload;
    }

    final type = _normalizedType(notification);
    return NotificationNavigationService.encodePayload({
      'route': _routeFor(notification, normalizedType: type),
      'action': type == 'reminder' ? 'open_checkin' : '',
      'type': type,
      'notificationId': _notificationId(notification),
      'source': 'server_sync',
    });
  }

  String _routeFor(
    Map<String, dynamic> notification, {
    required String normalizedType,
  }) {
    if (normalizedType == 'reminder') {
      return Routes.home;
    }
    if (normalizedType == 'earthquake_alert') {
      return Routes.earthquake;
    }
    return Routes.notifications;
  }
}
