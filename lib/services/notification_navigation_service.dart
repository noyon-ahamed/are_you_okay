import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';

final ValueNotifier<String?> pendingNotificationAction = ValueNotifier(null);

class NotificationNavigationService {
  static void handlePayload(String? payload) {
    final parsed = _parsePayload(payload);
    final route = parsed['route']?.toString();
    final action = parsed['action']?.toString();

    if (action != null && action.isNotEmpty) {
      pendingNotificationAction.value = action;
    }

    if (rootNavigatorKey.currentContext == null) return;

    final context = rootNavigatorKey.currentContext!;
    final targetRoute = route == null || route.isEmpty ? Routes.home : route;
    context.go(targetRoute);
  }

  static Map<String, dynamic> payloadForReminder({
    required String notificationId,
    String action = 'open_checkin',
    String route = Routes.home,
  }) {
    return <String, dynamic>{
      'notificationId': notificationId,
      'route': route,
      'action': action,
      'type': 'reminder',
      'source': 'local',
    };
  }

  static String encodePayload(Map<String, dynamic> payload) {
    return jsonEncode(payload);
  }

  static String? consumePendingAction() {
    final action = pendingNotificationAction.value;
    pendingNotificationAction.value = null;
    return action;
  }

  static Map<String, dynamic> _parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } catch (_) {
      // Fallback to legacy string payloads
    }

    if (payload.contains('checkin') || payload.contains('daily_checkin')) {
      return payloadForReminder(notificationId: payload);
    }
    if (payload.contains('earthquake')) {
      return <String, dynamic>{'route': Routes.notifications};
    }
    return <String, dynamic>{};
  }
}
