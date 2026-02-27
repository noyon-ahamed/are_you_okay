import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final moodLocalServiceProvider = Provider<MoodLocalService>((ref) => MoodLocalService());

/// Stores mood entries locally for offline support.
/// Pending moods are synced to the backend when connectivity is restored.
class MoodLocalService {
  static const String _boxName = 'mood_pending_box';
  Box? _box;

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  /// Save a mood locally (pending sync)
  Future<void> saveMoodLocally({
    required String mood,
    String? note,
  }) async {
    final box = await _getBox();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final entry = {
      'id': id,
      'mood': mood,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
      'isSynced': false,
    };
    await box.put(id, jsonEncode(entry));
    debugPrint('Mood saved locally: $mood (id: $id)');
  }

  /// Get all pending (unsynced) moods
  List<Map<String, dynamic>> getPendingMoods() {
    if (_box == null || !_box!.isOpen) return [];
    final List<Map<String, dynamic>> pending = [];
    for (var i = 0; i < _box!.length; i++) {
      try {
        final jsonString = _box!.getAt(i);
        if (jsonString != null) {
          final entry = jsonDecode(jsonString) as Map<String, dynamic>;
          if (entry['isSynced'] != true) {
            pending.add(entry);
          }
        }
      } catch (e) {
        debugPrint('Error parsing mood at index $i: $e');
      }
    }
    return pending;
  }

  /// Mark a mood as synced
  Future<void> markMoodAsSynced(String id) async {
    final box = await _getBox();
    final jsonString = box.get(id);
    if (jsonString != null) {
      try {
        final entry = jsonDecode(jsonString) as Map<String, dynamic>;
        entry['isSynced'] = true;
        await box.put(id, jsonEncode(entry));
      } catch (e) {
        debugPrint('Error marking mood as synced: $e');
      }
    }
  }

  /// Delete a synced mood entry
  Future<void> deleteMood(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  /// Clear all pending moods
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}
