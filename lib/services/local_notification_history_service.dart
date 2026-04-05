import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationHistoryService {
  static const String _storageKey = 'local_notification_history_v1';
  static const String _remoteCacheKey = 'remote_notification_cache_v1';
  static const String _remoteMetaKey = 'remote_notification_cache_meta_v1';
  static const int _maxItems = 100;
  static const int _maxRemoteCacheItems = 200;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    return _readList(_storageKey);
  }

  Future<List<Map<String, dynamic>>> getCachedRemoteNotifications() async {
    return _readList(_remoteCacheKey);
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
      'createdAt':
          notification['createdAt'] ?? DateTime.now().toIso8601String(),
      'isRead': notification['isRead'] == true,
      'isLocal': true,
      'surfacedLocally': notification['surfacedLocally'] != false,
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

  Future<void> cacheRemoteNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    final existing = await getCachedRemoteNotifications();
    final merged = _mergeNotifications([
      ...existing.map((item) => _normalizeNotification(item, isLocal: false)),
      ...notifications
          .map((item) => _normalizeNotification(item, isLocal: false)),
    ], preferRemote: true);

    if (merged.length > _maxRemoteCacheItems) {
      merged.removeRange(_maxRemoteCacheItems, merged.length);
    }

    await _writeList(_remoteCacheKey, merged);
  }

  Future<List<Map<String, dynamic>>> getMergedNotifications() async {
    final localNotifications = await getNotifications();
    final remoteNotifications = await getCachedRemoteNotifications();
    return _mergeNotifications([
      ...localNotifications
          .map((item) => _normalizeNotification(item, isLocal: true)),
      ...remoteNotifications
          .map((item) => _normalizeNotification(item, isLocal: false)),
    ], preferRemote: true);
  }

  Future<List<Map<String, dynamic>>>
      getPendingRemoteNotificationsForSurfacing() async {
    final localNotifications = await getNotifications();
    final remoteNotifications = await getCachedRemoteNotifications();

    final surfacedIds = localNotifications
        .where((item) => item['surfacedLocally'] != false)
        .map(_notificationId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    return remoteNotifications
        .map((item) => _normalizeNotification(item, isLocal: false))
        .where((item) {
      final id = _notificationId(item);
      return id != null &&
          id.isNotEmpty &&
          item['isRead'] != true &&
          !surfacedIds.contains(id);
    }).toList();
  }

  Future<void> markAsRead(String id) async {
    final items = await getNotifications();
    for (final item in items) {
      if (item['_id']?.toString() == id || item['id']?.toString() == id) {
        item['isRead'] = true;
      }
    }
    await _writeList(_storageKey, items);
    await _markRemoteAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final items = await getNotifications();
    for (final item in items) {
      item['isRead'] = true;
    }
    await _writeList(_storageKey, items);
    await _markAllRemoteAsRead();
  }

  Future<void> deleteNotification(String id, {String? payload}) async {
    final items = await getNotifications();
    items.removeWhere(
      (item) => _matchesNotification(item, id: id, payload: payload),
    );
    await _writeList(_storageKey, items);
    await _deleteRemoteNotification(id, payload: payload);
  }

  Future<bool> containsNotification(String id) async {
    final items = await getNotifications();
    return items.any((item) =>
        item['_id']?.toString() == id || item['id']?.toString() == id);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_remoteCacheKey);
    await prefs.remove(_remoteMetaKey);
  }

  Future<String?> getLatestRemoteCreatedAt() async {
    final cachedNotifications = await getCachedRemoteNotifications();
    if (cachedNotifications.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remoteMetaKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded['latestCreatedAt']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> setLatestRemoteCreatedAt(String? createdAt) async {
    if (createdAt == null || createdAt.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await getLatestRemoteCreatedAt();
    final currentDate = DateTime.tryParse(current ?? '');
    final nextDate = DateTime.tryParse(createdAt);

    if (nextDate == null) return;
    if (currentDate != null && !nextDate.isAfter(currentDate)) return;

    await prefs.setString(
      _remoteMetaKey,
      jsonEncode({'latestCreatedAt': nextDate.toIso8601String()}),
    );
  }

  Future<List<Map<String, dynamic>>> _readList(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
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

  Future<void> _writeList(
    String storageKey,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(items));
  }

  Future<void> _markRemoteAsRead(String id) async {
    final items = await getCachedRemoteNotifications();
    var changed = false;
    for (final item in items) {
      if (item['_id']?.toString() == id || item['id']?.toString() == id) {
        item['isRead'] = true;
        changed = true;
      }
    }
    if (changed) {
      await _writeList(_remoteCacheKey, items);
    }
  }

  Future<void> _markAllRemoteAsRead() async {
    final items = await getCachedRemoteNotifications();
    var changed = false;
    for (final item in items) {
      if (item['isRead'] != true) {
        item['isRead'] = true;
        changed = true;
      }
    }
    if (changed) {
      await _writeList(_remoteCacheKey, items);
    }
  }

  Future<void> _deleteRemoteNotification(String id, {String? payload}) async {
    final items = await getCachedRemoteNotifications();
    final before = items.length;
    items.removeWhere(
      (item) => _matchesNotification(item, id: id, payload: payload),
    );
    if (items.length != before) {
      await _writeList(_remoteCacheKey, items);
    }
  }

  bool _matchesNotification(
    Map<String, dynamic> item, {
    required String id,
    String? payload,
  }) {
    final matchesId =
        item['_id']?.toString() == id || item['id']?.toString() == id;
    final matchesPayload = payload != null &&
        payload.isNotEmpty &&
        item['payload']?.toString() == payload;
    return matchesId || matchesPayload;
  }

  String? _notificationId(Map<String, dynamic> notification) {
    return notification['_id']?.toString() ?? notification['id']?.toString();
  }

  List<Map<String, dynamic>> _mergeNotifications(
    List<Map<String, dynamic>> notifications, {
    required bool preferRemote,
  }) {
    final mergedByKey = <String, Map<String, dynamic>>{};

    for (final notification in notifications) {
      final key = _notificationKey(notification);
      final existing = mergedByKey[key];
      if (existing == null) {
        mergedByKey[key] = Map<String, dynamic>.from(notification);
        continue;
      }

      final candidateIsLocal = notification['isLocal'] == true;
      final existingIsLocal = existing['isLocal'] == true;

      final preferred = preferRemote
          ? (candidateIsLocal == existingIsLocal
              ? _mergeFields(existing, notification)
              : (candidateIsLocal
                  ? existing
                  : _mergeFields(existing, notification)))
          : _mergeFields(existing, notification);

      mergedByKey[key] = preferred;
    }

    final merged = mergedByKey.values.toList();
    merged.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return merged;
  }

  Map<String, dynamic> _mergeFields(
    Map<String, dynamic> existing,
    Map<String, dynamic> candidate,
  ) {
    final merged = <String, dynamic>{...existing, ...candidate};
    merged['isRead'] =
        existing['isRead'] == true || candidate['isRead'] == true;
    merged['isLocal'] =
        existing['isLocal'] == true && candidate['isLocal'] == true;

    if ((merged['payload']?.toString().isEmpty ?? true) &&
        existing['payload']?.toString().isNotEmpty == true) {
      merged['payload'] = existing['payload'];
    }

    if ((merged['title_en']?.toString().isEmpty ?? true) &&
        existing['title_en']?.toString().isNotEmpty == true) {
      merged['title_en'] = existing['title_en'];
    }

    return merged;
  }

  Map<String, dynamic> _normalizeNotification(
    Map<String, dynamic> notification, {
    required bool isLocal,
  }) {
    final id =
        notification['_id']?.toString() ?? notification['id']?.toString();

    return <String, dynamic>{
      ...notification,
      if (id != null && id.isNotEmpty) '_id': id,
      if (id != null && id.isNotEmpty) 'id': id,
      'createdAt':
          notification['createdAt'] ?? DateTime.now().toIso8601String(),
      'isRead': notification['isRead'] == true,
      'isLocal': notification['isLocal'] == true || isLocal,
      'surfacedLocally': notification['surfacedLocally'] == true ||
          (isLocal && notification['surfacedLocally'] != false),
    };
  }

  String _notificationKey(Map<String, dynamic> notification) {
    final id =
        notification['_id']?.toString() ?? notification['id']?.toString();
    if (id != null && id.isNotEmpty) {
      return 'id:$id';
    }

    final title = notification['title_en']?.toString() ??
        notification['title']?.toString() ??
        '';
    final body = notification['body']?.toString() ?? '';
    final createdAt = notification['createdAt']?.toString() ?? '';
    final type = notification['type']?.toString() ?? '';
    return 'fp:$type|$title|$body|$createdAt';
  }
}
