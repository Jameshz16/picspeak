import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageTimeTracker {
  static const _key = 'usage_timestamps';
  final SharedPreferences _prefs;

  UsageTimeTracker(this._prefs);

  /// Records the current app open timestamp.
  /// Keeps only the last 30 timestamps.
  Future<void> recordOpen() async {
    final timestamps = _getTimestamps();
    timestamps.add(DateTime.now().toIso8601String());

    // Keep only last 30 timestamps
    if (timestamps.length > 30) {
      timestamps.removeRange(0, timestamps.length - 30);
    }

    await _prefs.setString(_key, jsonEncode(timestamps));
  }

  /// Computes the optimal schedule time based on usage patterns.
  /// Returns the modal hour minus 30 minutes, or falls back to 16:00 (4 PM)
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

    // Subtract 30 minutes
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
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return [];
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }
}
