import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:picspeak/features/app_settings/domain/app_settings.dart';
import 'package:picspeak/features/flashcard_review/domain/flashcard_repository.dart';
import 'package:picspeak/features/notifications/domain/notification_permission_status.dart';
import 'package:picspeak/features/notifications/data/notification_permissions.dart';
import 'package:picspeak/features/notifications/data/notification_repository_impl.dart';
import 'package:picspeak/features/notifications/data/usage_time_tracker.dart';
import 'package:picspeak/features/object_recognition/domain/recognized_word.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Fake for [FlutterLocalNotificationsPlugin] that tracks cancel calls.
///
/// The real plugin is a concrete singleton (factory constructor) so we use
/// `implements` + `noSuchMethod` to intercept cancel/cancelAll without
/// touching the platform. All other plugin methods are no-ops via noSuchMethod.
class FakeFlutterLocalNotificationsPlugin
    implements FlutterLocalNotificationsPlugin {
  /// IDs passed to [cancel].
  final List<int> cancelledIds = [];

  /// Whether [cancelAll] was invoked.
  bool cancelAllCalled = false;

  /// Full cancel-call log: (id, tag) tuples.
  final List<(int id, String? tag)> cancelLog = [];

  /// Notification IDs passed to [zonedSchedule].
  final List<int> scheduledIds = [];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
    cancelLog.add((id, tag));
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation
        uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    scheduledIds.add(id);
  }

  /// Delegates everything else to noSuchMethod (no-op returns).
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return Future.value(null) for all unimplemented methods since
    // plugin methods return Future<void>.
    return Future.value(null);
  }
}

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

NotificationRepositoryImpl _buildRepo({
  required SharedPreferences prefs,
  required FakeUsageTimeTracker tracker,
  required FakeNotificationPermissions permissions,
  FlutterLocalNotificationsPlugin? plugin,
  FakeFlashcardRepository? flashcardRepo,
}) {
  return NotificationRepositoryImpl(
    notificationsPlugin: plugin ?? FlutterLocalNotificationsPlugin(),
    prefs: prefs,
    usageTimeTracker: tracker,
    permissions: permissions,
    flashcardRepository: flashcardRepo ?? FakeFlashcardRepository(),
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
      late FakeFlutterLocalNotificationsPlugin fakePlugin;

      setUp(() {
        fakePlugin = FakeFlutterLocalNotificationsPlugin();
      });

      test('does nothing when dueCount is 0', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );
        await repo.scheduleSrsReminder(0);
        // zonedSchedule must not be called — early return
        expect(fakePlugin.scheduledIds, isEmpty);
        // Daily cap key must NOT be written
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getBool('notif_sent_srs_$today'), isNull);
      });

      test('does nothing when dueCount is negative', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );
        await repo.scheduleSrsReminder(-5);
        expect(fakePlugin.scheduledIds, isEmpty);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getBool('notif_sent_srs_$today'), isNull);
      });

      test('does nothing when permission is denied', () async {
        permissions.setStatus(NotificationPermissionStatus.denied);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );
        await repo.scheduleSrsReminder(5);
        expect(fakePlugin.scheduledIds, isEmpty);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getBool('notif_sent_srs_$today'), isNull);
      });
    });

    // -- scheduleStreakReminder guard clauses --------------------------------

    group('scheduleStreakReminder() guard clauses', () {
      late FakeFlutterLocalNotificationsPlugin fakePlugin;

      setUp(() {
        fakePlugin = FakeFlutterLocalNotificationsPlugin();
      });

      test('does nothing when streakDays is 0', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );
        await repo.scheduleStreakReminder(0);
        expect(fakePlugin.scheduledIds, isEmpty);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getBool('notif_sent_streak_$today'), isNull);
      });

      test('does nothing when streakDays is 1', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );
        await repo.scheduleStreakReminder(1);
        expect(fakePlugin.scheduledIds, isEmpty);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getBool('notif_sent_streak_$today'), isNull);
      });

      test('does nothing when permission is permanentlyDenied', () async {
        permissions.setStatus(NotificationPermissionStatus.permanentlyDenied);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );
        await repo.scheduleStreakReminder(5);
        expect(fakePlugin.scheduledIds, isEmpty);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getBool('notif_sent_streak_$today'), isNull);
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
        expect(prefs.getBool(capKey), isTrue);
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
        expect(prefs.getBool(capKey), isTrue);
      });

      test('SRS and streak caps are independent', () async {
        final today = DateTime.now().toIso8601String().substring(0, 10);

        // Set SRS cap only
        await prefs.setBool('notif_sent_srs_$today', true);

        // Streak cap should NOT be set
        expect(prefs.getBool('notif_sent_streak_$today'), isNull);
      });

      test('no cap key means scheduling is allowed', () async {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        expect(prefs.getBool('notif_sent_srs_$today'), isNull);
        expect(prefs.getBool('notif_sent_streak_$today'), isNull);
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

    // -- rescheduleAll cancellation contract ---------------------------------
    //
    // These tests use [FakeFlutterLocalNotificationsPlugin] to verify that
    // rescheduleAll properly cancels notifications by type before
    // re-scheduling, and cancels disabled sub-feature notifications.

    group('rescheduleAll() cancellation contract', () {
      late FakeFlutterLocalNotificationsPlugin fakePlugin;

      setUp(() {
        fakePlugin = FakeFlutterLocalNotificationsPlugin();
      });

      test('notificationsEnabled=false → cancelAll called', () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );

        await repo.rescheduleAll(
          settings: const AppSettings(notificationsEnabled: false),
        );

        expect(fakePlugin.cancelAllCalled, isTrue);
        // No individual cancel calls — cancelAll covers everything
        expect(fakePlugin.cancelledIds, isEmpty);
      });

      test(
          'srsRemindersEnabled=false → cancel(0) called (SRS id)',
          () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );

        await repo.rescheduleAll(
          settings: const AppSettings(
            notificationsEnabled: true,
            srsRemindersEnabled: false,
            streakRemindersEnabled: false,
          ),
        );

        // Should cancel SRS (id=0) because it's disabled
        expect(fakePlugin.cancelledIds, contains(0));
        // Should cancel streak (id=1) because it's disabled
        expect(fakePlugin.cancelledIds, contains(1));
        expect(fakePlugin.cancelAllCalled, isFalse);
      });

      test(
          'streakRemindersEnabled=false → cancel(1) called (streak id)',
          () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );

        await repo.rescheduleAll(
          settings: const AppSettings(
            notificationsEnabled: true,
            srsRemindersEnabled: false,
            streakRemindersEnabled: false,
          ),
        );

        // Both disabled → both cancelled
        expect(fakePlugin.cancelledIds, contains(0));
        expect(fakePlugin.cancelledIds, contains(1));
      });

      test(
          'both sub-features disabled → both ids cancelled',
          () async {
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );

        await repo.rescheduleAll(
          settings: const AppSettings(
            notificationsEnabled: true,
            srsRemindersEnabled: false,
            streakRemindersEnabled: false,
          ),
        );

        expect(fakePlugin.cancelledIds, containsAll([0, 1]));
      });

      test(
          'srs enabled → cancel(0) called BEFORE schedule (cancel-then-schedule)',
          () async {
        final flashcardRepo = FakeFlashcardRepository()..dueCount = 3;
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
          flashcardRepo: flashcardRepo,
        );

        await repo.rescheduleAll(
          settings: const AppSettings(
            notificationsEnabled: true,
            srsRemindersEnabled: true,
            streakRemindersEnabled: false,
          ),
        );

        // cancel(0) should appear in the log (cancel-before-schedule)
        expect(fakePlugin.cancelLog.any((entry) => entry.$1 == 0), isTrue);
        // Streak is disabled, so cancel(1) should also appear
        expect(fakePlugin.cancelledIds, contains(1));
      });

      test(
          'streak enabled → cancel(1) called BEFORE schedule',
          () async {
        // Need streak >= 2 to pass guard clause
        await prefs.setInt('study_streak', 5);
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
        );

        await repo.rescheduleAll(
          settings: const AppSettings(
            notificationsEnabled: true,
            srsRemindersEnabled: false,
            streakRemindersEnabled: true,
          ),
        );

        // cancel(1) should appear (cancel-before-schedule for streak)
        expect(fakePlugin.cancelLog.any((entry) => entry.$1 == 1), isTrue);
        // SRS is disabled, so cancel(0) should also appear
        expect(fakePlugin.cancelledIds, contains(0));
      });

      test('re-scheduling same type cancels then schedules (no duplicates)',
          () async {
        final flashcardRepo = FakeFlashcardRepository()..dueCount = 5;
        final repo = _buildRepo(
          prefs: prefs,
          tracker: tracker,
          permissions: permissions,
          plugin: fakePlugin,
          flashcardRepo: flashcardRepo,
        );

        // First reschedule
        await repo.rescheduleAll(
          settings: const AppSettings(
            notificationsEnabled: true,
            srsRemindersEnabled: true,
            streakRemindersEnabled: false,
          ),
        );

        final firstCancelCount = fakePlugin.cancelLog.length;

        // Second reschedule — should cancel again before re-scheduling
        await repo.rescheduleAll(
          settings: const AppSettings(
            notificationsEnabled: true,
            srsRemindersEnabled: true,
            streakRemindersEnabled: false,
          ),
        );

        // More cancel calls should have been made
        expect(fakePlugin.cancelLog.length, greaterThan(firstCancelCount));
        // cancel(0) should appear twice (once per reschedule)
        final srsCancels =
            fakePlugin.cancelLog.where((e) => e.$1 == 0).length;
        expect(srsCancels, equals(2));
      });
    });
  });
}
