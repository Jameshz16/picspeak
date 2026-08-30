import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:picspeak/features/app_settings/domain/app_settings.dart';

void main() {
  group('AppSettings', () {
    group('fromJson() backward compatibility', () {
      test('old JSON without notification fields uses defaults', () {
        final oldJson = <String, dynamic>{
          'locale': 'en',
          'voiceSpeed': 1.5,
          'themeMode': 1,
        };

        final settings = AppSettings.fromJson(oldJson);

        expect(settings.locale, equals('en'));
        expect(settings.voiceSpeed, equals(1.5));
        expect(settings.themeMode, equals(ThemeMode.light));
        // Notification defaults
        expect(settings.notificationsEnabled, isFalse);
        expect(settings.srsRemindersEnabled, isTrue);
        expect(settings.streakRemindersEnabled, isTrue);
        expect(settings.quietHoursEnabled, isTrue);
        expect(settings.customScheduleTime, isNull);
      });

      test('completely empty JSON uses all defaults', () {
        final settings = AppSettings.fromJson(<String, dynamic>{});

        expect(settings.locale, equals('es'));
        expect(settings.voiceSpeed, equals(1.0));
        expect(settings.themeMode, equals(ThemeMode.system));
        expect(settings.notificationsEnabled, isFalse);
        expect(settings.srsRemindersEnabled, isTrue);
        expect(settings.streakRemindersEnabled, isTrue);
        expect(settings.quietHoursEnabled, isTrue);
        expect(settings.customScheduleTime, isNull);
      });

      test('null values in JSON use defaults', () {
        final json = <String, dynamic>{
          'locale': null,
          'voiceSpeed': null,
          'themeMode': null,
          'notificationsEnabled': null,
          'srsRemindersEnabled': null,
          'streakRemindersEnabled': null,
          'quietHoursEnabled': null,
          'customScheduleTime': null,
        };

        final settings = AppSettings.fromJson(json);

        expect(settings.locale, equals('es'));
        expect(settings.voiceSpeed, equals(1.0));
        expect(settings.notificationsEnabled, isFalse);
        expect(settings.srsRemindersEnabled, isTrue);
      });
    });

    group('toJson() / fromJson() round-trip', () {
      test('new fields serialize and deserialize correctly', () {
        const original = AppSettings(
          locale: 'es',
          voiceSpeed: 1.2,
          themeMode: ThemeMode.dark,
          notificationsEnabled: true,
          srsRemindersEnabled: false,
          streakRemindersEnabled: false,
          quietHoursEnabled: false,
          customScheduleTime: '20:30',
        );

        final json = original.toJson();
        final restored = AppSettings.fromJson(json);

        expect(restored.locale, equals(original.locale));
        expect(restored.voiceSpeed, equals(original.voiceSpeed));
        expect(restored.themeMode, equals(original.themeMode));
        expect(restored.notificationsEnabled,
            equals(original.notificationsEnabled));
        expect(restored.srsRemindersEnabled,
            equals(original.srsRemindersEnabled));
        expect(restored.streakRemindersEnabled,
            equals(original.streakRemindersEnabled));
        expect(restored.quietHoursEnabled, equals(original.quietHoursEnabled));
        expect(restored.customScheduleTime,
            equals(original.customScheduleTime));
      });

      test('null customScheduleTime serializes as null', () {
        const settings = AppSettings(customScheduleTime: null);
        final json = settings.toJson();
        expect(json['customScheduleTime'], isNull);

        final restored = AppSettings.fromJson(json);
        expect(restored.customScheduleTime, isNull);
      });
    });

    group('copyWith()', () {
      test('preserves existing values when no args provided', () {
        const original = AppSettings(
          locale: 'en',
          voiceSpeed: 1.5,
          notificationsEnabled: true,
          customScheduleTime: '10:00',
        );

        final copied = original.copyWith();

        expect(copied.locale, equals('en'));
        expect(copied.voiceSpeed, equals(1.5));
        expect(copied.notificationsEnabled, isTrue);
        expect(copied.customScheduleTime, equals('10:00'));
      });

      test('updates specified fields while preserving others', () {
        const original = AppSettings(
          locale: 'en',
          voiceSpeed: 1.5,
          notificationsEnabled: true,
          srsRemindersEnabled: true,
        );

        final copied = original.copyWith(
          notificationsEnabled: false,
          srsRemindersEnabled: false,
        );

        expect(copied.locale, equals('en'));
        expect(copied.voiceSpeed, equals(1.5));
        expect(copied.notificationsEnabled, isFalse);
        expect(copied.srsRemindersEnabled, isFalse);
        expect(copied.streakRemindersEnabled, isTrue); // preserved
        expect(copied.quietHoursEnabled, isTrue); // preserved
      });

      test('clearCustomScheduleTime sets customScheduleTime to null', () {
        const original = AppSettings(customScheduleTime: '14:00');

        final cleared = original.copyWith(clearCustomScheduleTime: true);

        expect(cleared.customScheduleTime, isNull);
      });

      test('clearCustomScheduleTime takes precedence over customScheduleTime',
          () {
        const original = AppSettings(customScheduleTime: '14:00');

        final result = original.copyWith(
          clearCustomScheduleTime: true,
          customScheduleTime: '20:00',
        );

        // clearCustomScheduleTime should win
        expect(result.customScheduleTime, isNull);
      });

      test('can update customScheduleTime normally', () {
        const original = AppSettings(customScheduleTime: '14:00');

        final updated = original.copyWith(customScheduleTime: '20:00');

        expect(updated.customScheduleTime, equals('20:00'));
      });
    });
  });
}
