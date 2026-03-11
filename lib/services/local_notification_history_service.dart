import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationHistoryService {
  static const String _storageKey = 'local_notification_history_v1';
  static const int _maxItems = 100;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveNotification(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getNotifications();
    final notificationId =
        notification['_id']?.toString() ?? notification['id']?.toString();
    if (notificationId == null || notificationId.isEmpty) return;

    items.removeWhere((item) =>
        item['_id']?.toString() == notificationId ||
        item['id']?.toString() == notificationId);

    final normalized = <String, dynamic>{
      '_id': notificationId,
      'id': notificationId,
      'title': notification['title'] ?? 'Reminder',
      'title_en': notification['title_en'] ?? notification['title'],
      'body': notification['body'] ?? '',
      'type': notification['type'] ?? 'reminder',
      'payload': notification['payload'],
      'createdAt': notification['createdAt'] ??
          DateTime.now().toIso8601String(),
      'isRead': notification['isRead'] == true,
      'isLocal': true,
      'source': notification['source'] ?? 'local',
      'scheduledFor': notification['scheduledFor'],
      'notificationId': notification['notificationId'],
    };

    items.insert(0, normalized);
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }

    await prefs.setString(_storageKey, jsonEncode(items));
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getNotifications();
    for (final item in items) {
      if (item['_id']?.toString() == id || item['id']?.toString() == id) {
        item['isRead'] = true;
      }
    }
    await prefs.setString(_storageKey, jsonEncode(items));
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getNotifications();
    for (final item in items) {
      item['isRead'] = true;
    }
    await prefs.setString(_storageKey, jsonEncode(items));
  }

  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getNotifications();
    items.removeWhere((item) =>
        item['_id']?.toString() == id || item['id']?.toString() == id);
    await prefs.setString(_storageKey, jsonEncode(items));
  }

  Future<bool> containsNotification(String id) async {
    final items = await getNotifications();
    return items.any((item) =>
        item['_id']?.toString() == id || item['id']?.toString() == id);
  }
}
