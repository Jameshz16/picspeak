import 'package:flutter_test/flutter_test.dart';

import 'package:picspeak/features/app_settings/domain/app_settings.dart';
import 'package:picspeak/features/notifications/domain/notification_repository.dart';

/// Simple mock implementation to verify the abstract interface contract.
class MockNotificationRepository implements NotificationRepository {
  bool? lastPermissionResult;
  bool? lastPermissionStatusResult;
  int? lastSrsDueCount;
  int? lastStreakDays;
  bool cancelAllCalled = false;
  String? lastCancelledType;
  AppSettings? lastRescheduleSettings;

  @override
  Future<bool> requestPermission() async {
    return lastPermissionResult ?? false;
  }

  @override
  Future<bool> getPermissionStatus() async {
    return lastPermissionStatusResult ?? false;
  }

  @override
  Future<void> scheduleSrsReminder(int dueCount) async {
    lastSrsDueCount = dueCount;
  }

  @override
  Future<void> scheduleStreakReminder(int streakDays) async {
    lastStreakDays = streakDays;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
  }

  @override
  Future<void> cancelByType(String type) async {
    lastCancelledType = type;
  }

  @override
  Future<void> rescheduleAll({required AppSettings settings}) async {
    lastRescheduleSettings = settings;
  }
}

void main() {
  group('NotificationRepository', () {
    late MockNotificationRepository repo;

    setUp(() {
      repo = MockNotificationRepository();
    });

    test('interface has all expected methods', () {
      // Verify the mock implements all abstract methods
      expect(repo, isA<NotificationRepository>());
    });

    test('requestPermission returns bool', () async {
      repo.lastPermissionResult = true;
      final result = await repo.requestPermission();
      expect(result, isTrue);

      repo.lastPermissionResult = false;
      final result2 = await repo.requestPermission();
      expect(result2, isFalse);
    });

    test('getPermissionStatus returns bool', () async {
      repo.lastPermissionStatusResult = true;
      final result = await repo.getPermissionStatus();
      expect(result, isTrue);
    });

    test('scheduleSrsReminder accepts due count', () async {
      await repo.scheduleSrsReminder(5);
      expect(repo.lastSrsDueCount, equals(5));
    });

    test('scheduleStreakReminder accepts streak days', () async {
      await repo.scheduleStreakReminder(7);
      expect(repo.lastStreakDays, equals(7));
    });

    test('cancelAll marks as called', () async {
      await repo.cancelAll();
      expect(repo.cancelAllCalled, isTrue);
    });

    test('cancelByType passes type string', () async {
      await repo.cancelByType('srs');
      expect(repo.lastCancelledType, equals('srs'));

      await repo.cancelByType('streak');
      expect(repo.lastCancelledType, equals('streak'));
    });

    test('rescheduleAll passes settings', () async {
      const settings = AppSettings(notificationsEnabled: true);
      await repo.rescheduleAll(settings: settings);
      expect(repo.lastRescheduleSettings, equals(settings));
    });
  });
}
