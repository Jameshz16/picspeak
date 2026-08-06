import 'notification_permission_status.dart';
import '../../app_settings/domain/app_settings.dart';

abstract class NotificationRepository {
  /// Request notification permission from the OS.
  /// Returns true if permission was granted.
  Future<bool> requestPermission();

  /// Request notification permission from the OS with detailed status.
  /// Use this when you need to distinguish denied vs permanently denied.
  Future<NotificationPermissionStatus> requestPermissionDetailed();

  /// Check current notification permission status.
  /// Returns true if permission is granted.
  Future<bool> getPermissionStatus();

  /// Schedule an SRS review reminder with the given due card count.
  /// When [settings] is provided, uses quietHoursEnabled and customScheduleTime.
  Future<void> scheduleSrsReminder(int dueCount, {AppSettings? settings});

  /// Schedule a streak reminder with the given streak day count.
  /// When [settings] is provided, uses quietHoursEnabled and customScheduleTime.
  Future<void> scheduleStreakReminder(int streakDays, {AppSettings? settings});

  /// Cancel all scheduled notifications.
  Future<void> cancelAll();

  /// Cancel scheduled notifications by type (e.g., 'srs', 'streak').
  Future<void> cancelByType(String type);

  /// Reschedule all notifications based on current settings.
  Future<void> rescheduleAll({required AppSettings settings});
}
