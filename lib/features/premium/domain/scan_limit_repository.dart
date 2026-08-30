/// Repository interface for managing daily scan limits.
abstract class ScanLimitRepository {
  /// Maximum number of free scans per day.
  static const int dailyFreeLimit = 5;

  /// Returns how many scans the user has used today.
  Future<int> getTodayScanCount();

  /// Returns how many scans remain today (0 if at limit).
  /// Returns -1 if the user is premium (unlimited).
  Future<int> getRemainingScans({required bool isPremium});

  /// Records a new scan. Increments today's counter.
  Future<void> recordScan();

  /// Grants bonus scans by decrementing the used count.
  /// Used when the user watches a rewarded ad.
  Future<void> grantBonusScans(int count);

  /// Resets the daily counter (called automatically at midnight or new day).
  Future<void> resetDaily();

  /// Whether the user has reached the daily scan limit.
  Future<bool> hasReachedLimit({required bool isPremium});
}
