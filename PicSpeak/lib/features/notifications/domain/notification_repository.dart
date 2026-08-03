abstract class NotificationRepository {
  /// Request notification permission from the OS.
  /// Returns true if permission was granted.
  Future<bool> requestPermission();

  /// Check current notification permission status.
  /// Returns true if permission is granted.
  Future<bool> getPermissionStatus();

  /// Schedule an SRS review reminder with the given due card count.
  Future<void> scheduleSrsReminder(int dueCount);

  /// Schedule a streak reminder with the given streak day count.
  Future<void> scheduleStreakReminder(int streakDays);

  /// Cancel all scheduled notifications.
  Future<void> cancelAll();

  /// Cancel scheduled notifications by type (e.g., 'srs', 'streak').
  Future<void> cancelByType(String type);
}
