import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/current_user.dart';

class UsageTimeTracker {
  final SharedPreferences _prefs;

  UsageTimeTracker(this._prefs);

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  /// Reads a user-scoped key with a one-time migration from the legacy
  /// unscoped key. Once migrated the legacy key is removed so a future
  /// different user on the same device never sees the previous user's data.
  String? _getWithLegacy(String base) {
    final scoped = _prefs.getString(_key(base));
    if (scoped != null) return scoped;
    if (currentUserId.isEmpty) return null;
    final legacy = _prefs.getString(base);
    if (legacy != null) {
      _prefs.setString(_key(base), legacy);
      _prefs.remove(base);
      return legacy;
    }
    return null;
  }

  /// Records the current app open timestamp.
  /// Keeps only the last 30 timestamps.
  Future<void> recordOpen() async {
    final timestamps = _getTimestamps();
    timestamps.add(DateTime.now().toIso8601String());

    // Keep only last 30 timestamps
    if (timestamps.length > 30) {
      timestamps.removeRange(0, timestamps.length - 30);
    }

    await _prefs.setString(_key('usage_timestamps'), jsonEncode(timestamps));
  }

  /// Computes the optimal schedule time based on usage patterns.
  /// Returns the modal hour minus 1 hour, or falls back to 16:00 (4 PM)
  /// if there are fewer than 5 data points.
  Future<TimeOfDay> getScheduleTime() async {
    final timestamps = _getTimestamps();

    if (timestamps.length < 5) {
      // Fallback to 4:00 PM
      return const TimeOfDay(hour: 16, minute: 0);
    }

    // Compute modal hour (most frequent hour)
    final hourCounts = <int, int>{};
    for (final ts in timestamps) {
      try {
        final dt = DateTime.parse(ts);
        final hour = dt.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      } catch (_) {
        // Skip invalid timestamps
      }
    }

    if (hourCounts.isEmpty) {
      return const TimeOfDay(hour: 16, minute: 0);
    }

    // Find modal hour
    int modalHour = 16;
    int maxCount = 0;
    for (final entry in hourCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        modalHour = entry.key;
      }
    }

    // Subtract 1 hour (schedule an hour before the user's typical open time)
    int scheduleHour = modalHour - 1;
    if (scheduleHour < 0) {
      scheduleHour = 23;
    }

    // Clamp to valid hours (8-20)
    if (scheduleHour < 8) {
      scheduleHour = 8;
    } else if (scheduleHour > 20) {
      scheduleHour = 20;
    }

    return TimeOfDay(hour: scheduleHour, minute: 0);
  }

  List<String> _getTimestamps() {
    final jsonString = _getWithLegacy('usage_timestamps');
    if (jsonString == null) return [];
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }
}
