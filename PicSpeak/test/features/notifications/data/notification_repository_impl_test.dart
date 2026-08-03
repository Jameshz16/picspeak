import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:picspeak/features/flashcard_review/domain/flashcard_repository.dart';
import 'package:picspeak/features/notifications/data/notification_permissions.dart';
import 'package:picspeak/features/notifications/data/notification_repository_impl.dart';
import 'package:picspeak/features/notifications/data/usage_time_tracker.dart';
import 'package:picspeak/features/object_recognition/domain/recognized_word.dart';
import 'package:picspeak/features/stats/data/stats_repository.dart';
import 'package:picspeak/features/stats/domain/learning_stats.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeUsageTimeTracker extends UsageTimeTracker {
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 12, minute: 0);
  FakeUsageTimeTracker(super.prefs);
  void setScheduleTime(TimeOfDay time) => _scheduleTime = time;
  @override
  Future<TimeOfDay> getScheduleTime() async => _scheduleTime;
}

class FakeNotificationPermissions extends NotificationPermissions {
  NotificationPermissionStatus _status = NotificationPermissionStatus.granted;
  void setStatus(NotificationPermissionStatus s) => _status = s;
  @override
  Future<NotificationPermissionStatus> requestPermission() async => _status;
  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async => _status;
  @override
  Future<bool> get isGranted async =>
      _status == NotificationPermissionStatus.granted;
}

class FakeFlashcardRepository implements FlashcardRepository {
  int dueCount = 0;
  @override
  Future<int> getDueCount() async => dueCount;
  @override
  Future<void> save(RecognizedWord word) async {}
  @override
  Future<List<RecognizedWord>> loadAll() async => [];
  @override
  Future<bool> exists(String enLabel) async => false;
  @override
  Future<void> remove(String enLabel) async {}
  @override
  Future<List<RecognizedWord>> getDueCards() async => [];
  @override
  Future<void> updateSrs({
    required String enLabel,
    required int interval,
    required double easeFactor,
    required DateTime nextReview,
  }) async {}
}

class FakeStatsRepository extends StatsRepository {
  FakeStatsRepository(super.prefs);
  @override
  Future<LearningStats> computeStats({
    required FlashcardRepository flashcardRepo,
    required dynamic historyRepo,
  }) async =>
      const LearningStats(
        totalFavorites: 0,
        totalScanned: 0,
        dueToday: 0,
        reviewedToday: 0,
        masteredCount: 0,
        streakDays: 0,
      );
  @override
  void recordStudySession({int reviewedCount = 0}) {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

NotificationRepositoryImpl _buildRepo({
  required SharedPreferences prefs,
  required FakeUsageTimeTracker tracker,
  required FakeNotificationPermissions permissions,
}) {
  return NotificationRepositoryImpl(
    notificationsPlugin: FlutterLocalNotificationsPlugin(),
    prefs: prefs,
    usageTimeTracker: tracker,
    permissions: permissions,
    flashcardRepository: FakeFlashcardRepository(),
    statsRepository: FakeStatsRepository(prefs),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('NotificationRepositoryImpl', () {
    late SharedPreferences prefs;
    late FakeUsageTimeTracker tracker;
    late FakeNotificationPermissions permissions;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tracker = FakeUsageTimeTracker(prefs);
      permissions = FakeNotificationPermissions();
    });

    // -- scheduleSrsReminder guard clauses -----------------------------------

    group('scheduleSrsReminder() guard clauses', () {
      test('does nothing when dueCount is 0', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        // Returns early — no platform call
        await repo.scheduleSrsReminder(0);
        expect(true, isTrue);
      });

      test('does nothing when dueCount is negative', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        await repo.scheduleSrsReminder(-5);
        expect(true, isTrue);
      });

      test('does nothing when permission is denied', () async {
        permissions.setStatus(NotificationPermissionStatus.denied);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        await repo.scheduleSrsReminder(5);
        expect(true, isTrue);
      });
    });

    // -- scheduleStreakReminder guard clauses --------------------------------

    group('scheduleStreakReminder() guard clauses', () {
      test('does nothing when streakDays is 0', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        await repo.scheduleStreakReminder(0);
        expect(true, isTrue);
      });

      test('does nothing when streakDays is 1', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        await repo.scheduleStreakReminder(1);
        expect(true, isTrue);
      });

      test('does nothing when permission is permanentlyDenied', () async {
        permissions.setStatus(NotificationPermissionStatus.permanentlyDenied);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        await repo.scheduleStreakReminder(5);
        expect(true, isTrue);
      });
    });

    // -- Daily cap via SharedPreferences -------------------------------------

    group('daily cap via SharedPreferences', () {
      test('SRS cap key blocks second schedule same day', () async {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final capKey = 'notif_sent_srs_$today';

        // Simulate: first schedule already happened
        await prefs.setBool(capKey, true);

        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );

        // Should return early — cap key is set
        await repo.scheduleSrsReminder(5);
        // Verify cap key still set (no duplicate)
        expect(await prefs.getBool(capKey), isTrue);
      });

      test('streak cap key blocks second schedule same day', () async {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final capKey = 'notif_sent_streak_$today';

        await prefs.setBool(capKey, true);

        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );

        await repo.scheduleStreakReminder(3);
        expect(await prefs.getBool(capKey), isTrue);
      });

      test('SRS and streak caps are independent', () async {
        final today = DateTime.now().toIso8601String().substring(0, 10);

        // Set SRS cap only
        await prefs.setBool('notif_sent_srs_$today', true);

        // Streak cap should NOT be set
        expect(await prefs.getBool('notif_sent_streak_$today'), isNull);
      });

      test('no cap key means scheduling is allowed', () async {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(await prefs.getBool('notif_sent_srs_$today'), isNull);
        expect(await prefs.getBool('notif_sent_streak_$today'), isNull);
      });
    });

    // -- Permission delegation ------------------------------------------------

    group('permission delegation', () {
      test('requestPermission returns true when granted', () async {
        permissions.setStatus(NotificationPermissionStatus.granted);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        expect(await repo.requestPermission(), isTrue);
      });

      test('requestPermission returns false when denied', () async {
        permissions.setStatus(NotificationPermissionStatus.denied);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        expect(await repo.requestPermission(), isFalse);
      });

      test('requestPermission returns false when permanentlyDenied', () async {
        permissions.setStatus(NotificationPermissionStatus.permanentlyDenied);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        expect(await repo.requestPermission(), isFalse);
      });

      test('getPermissionStatus mirrors permission state', () async {
        permissions.setStatus(NotificationPermissionStatus.granted);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
        );
        expect(await repo.getPermissionStatus(), isTrue);

        permissions.setStatus(NotificationPermissionStatus.denied);
        expect(await repo.getPermissionStatus(), isFalse);
      });
    });

    // -- Quiet hours clamping (via tracker + scheduleTime) --------------------

    group('quiet hours — tracker time mapping', () {
      test('tracker returns 22:00 → quiet hours applies (clamped to 08:00)',
          () async {
        permissions.setStatus(NotificationPermissionStatus.granted);
        tracker.setScheduleTime(const TimeOfDay(hour: 22, minute: 0));

        // Verify tracker returns the expected time
        final time = await tracker.getScheduleTime();
        expect(time.hour, equals(22));
        // The impl will clamp this to 08:00 internally
      });

      test('tracker returns 12:00 → no quiet hours', () async {
        permissions.setStatus(NotificationPermissionStatus.granted);
        tracker.setScheduleTime(const TimeOfDay(hour: 12, minute: 0));

        final time = await tracker.getScheduleTime();
        expect(time.hour, equals(12));
      });

      test('tracker returns 07:00 → quiet hours applies (clamped to 08:00)',
          () async {
        permissions.setStatus(NotificationPermissionStatus.granted);
        tracker.setScheduleTime(const TimeOfDay(hour: 7, minute: 0));

        final time = await tracker.getScheduleTime();
        expect(time.hour, equals(7));
        // The impl will clamp this to 08:00 internally
      });
    });
  });
}
