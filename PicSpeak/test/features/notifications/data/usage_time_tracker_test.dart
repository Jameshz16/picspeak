import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:picspeak/features/notifications/data/usage_time_tracker.dart';

void main() {
  group('UsageTimeTracker', () {
    late SharedPreferences prefs;
    late UsageTimeTracker tracker;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tracker = UsageTimeTracker(prefs);
    });

    group('getScheduleTime()', () {
      test('empty timestamps → returns 16:00', () async {
        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 16, minute: 0)));
      });

      test('fewer than 5 timestamps → returns 16:00', () async {
        // Add 4 timestamps (less than 5)
        final timestamps = [
          DateTime(2026, 1, 1, 10).toIso8601String(),
          DateTime(2026, 1, 1, 11).toIso8601String(),
          DateTime(2026, 1, 1, 12).toIso8601String(),
          DateTime(2026, 1, 1, 13).toIso8601String(),
        ];
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 16, minute: 0)));
      });

      test('5+ timestamps → modal hour minus 1 hour', () async {
        // All opens at hour 14 → modal = 14, schedule = 13
        final timestamps = List.generate(
          5,
          (i) => DateTime(2026, 1, 1, 14, i * 10).toIso8601String(),
        );
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 13, minute: 0)));
      });

      test('modal hour 0 (midnight) → wraps to 23, clamps to 20', () async {
        // All opens at hour 0 → modal = 0, 0-1 = -1 → wraps to 23 → clamps to 20
        final timestamps = List.generate(
          5,
          (i) => DateTime(2026, 1, 1, 0, i * 10).toIso8601String(),
        );
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 20, minute: 0)));
      });

      test('modal hour 1 (1 AM) → subtracts to 0, clamps to 8', () async {
        final timestamps = List.generate(
          5,
          (i) => DateTime(2026, 1, 1, 1, i * 10).toIso8601String(),
        );
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 8, minute: 0)));
      });

      test('modal hour 9 → schedule = 8 (within valid range)', () async {
        final timestamps = List.generate(
          5,
          (i) => DateTime(2026, 1, 1, 9, i * 10).toIso8601String(),
        );
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 8, minute: 0)));
      });

      test('modal hour 21 → schedule = 20 (clamped)', () async {
        final timestamps = List.generate(
          5,
          (i) => DateTime(2026, 1, 1, 21, i * 10).toIso8601String(),
        );
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 20, minute: 0)));
      });

      test('modal hour 22 → schedule = 21, clamped to 20', () async {
        final timestamps = List.generate(
          5,
          (i) => DateTime(2026, 1, 1, 22, i * 10).toIso8601String(),
        );
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 20, minute: 0)));
      });

      test('mixed hours → picks most frequent (modal)', () async {
        // 3 opens at hour 10, 2 opens at hour 15 → modal = 10, schedule = 9
        final timestamps = [
          DateTime(2026, 1, 1, 10).toIso8601String(),
          DateTime(2026, 1, 1, 10, 15).toIso8601String(),
          DateTime(2026, 1, 1, 10, 30).toIso8601String(),
          DateTime(2026, 1, 1, 15).toIso8601String(),
          DateTime(2026, 1, 1, 15, 30).toIso8601String(),
        ];
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        expect(result, equals(const TimeOfDay(hour: 9, minute: 0)));
      });

      test('invalid timestamps are skipped gracefully', () async {
        final timestamps = [
          'not-a-date',
          DateTime(2026, 1, 1, 14).toIso8601String(),
          'also-bad',
          DateTime(2026, 1, 1, 14, 10).toIso8601String(),
          DateTime(2026, 1, 1, 14, 20).toIso8601String(),
          DateTime(2026, 1, 1, 14, 30).toIso8601String(),
          DateTime(2026, 1, 1, 14, 40).toIso8601String(),
        ];
        await prefs.setString('usage_timestamps', jsonEncode(timestamps));

        final result = await tracker.getScheduleTime();
        // 5 valid timestamps at hour 14 → modal = 14, schedule = 13
        expect(result, equals(const TimeOfDay(hour: 13, minute: 0)));
      });
    });

    group('recordOpen()', () {
      test('stores timestamp in SharedPreferences', () async {
        await tracker.recordOpen();

        final jsonString = prefs.getString('usage_timestamps');
        expect(jsonString, isNotNull);

        final list = jsonDecode(jsonString!) as List;
        expect(list.length, equals(1));
      });

      test('keeps only last 30 timestamps', () async {
        // Pre-populate with 30 timestamps
        final existing = List.generate(
          30,
          (i) => DateTime(2026, 1, 1, 8, i).toIso8601String(),
        );
        await prefs.setString('usage_timestamps', jsonEncode(existing));

        await tracker.recordOpen();

        final jsonString = prefs.getString('usage_timestamps');
        final list = jsonDecode(jsonString!) as List;
        expect(list.length, equals(30));
        // First entry should be the second-old one (index 1 of original)
        expect(list.first, equals(existing[1]));
      });
    });
  });
}
