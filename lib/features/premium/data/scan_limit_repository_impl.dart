import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/current_user.dart';
import '../domain/scan_limit_repository.dart';

/// SharedPreferences-backed implementation of daily scan limits.
///
/// Stores two keys per user:
///   - `{userId}_scan_count` — int, number of scans today
///   - `{userId}_scan_date`  — String (yyyy-MM-dd), the date of the count
///
/// On each read, if the stored date differs from today, the counter resets
/// automatically (lazy reset — no timer needed).
class ScanLimitRepositoryImpl implements ScanLimitRepository {
  final SharedPreferences _prefs;

  ScanLimitRepositoryImpl(this._prefs);

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  String get _today => _dateKey(DateTime.now());

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Ensures the counter is for today; resets if the stored date is stale.
  void _ensureToday() {
    final storedDate = _prefs.getString(_key('scan_date'));
    if (storedDate != _today) {
      _prefs.setInt(_key('scan_count'), 0);
      _prefs.setString(_key('scan_date'), _today);
    }
  }

  @override
  Future<int> getTodayScanCount() async {
    _ensureToday();
    return _prefs.getInt(_key('scan_count')) ?? 0;
  }

  @override
  Future<int> getRemainingScans({required bool isPremium}) async {
    if (isPremium) return -1; // unlimited
    final used = await getTodayScanCount();
    final remaining = ScanLimitRepository.dailyFreeLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Future<void> recordScan() async {
    _ensureToday();
    final current = _prefs.getInt(_key('scan_count')) ?? 0;
    await _prefs.setInt(_key('scan_count'), current + 1);
  }

  @override
  Future<void> grantBonusScans(int count) async {
    _ensureToday();
    final current = _prefs.getInt(_key('scan_count')) ?? 0;
    final newValue = (current - count).clamp(0, 999999);
    await _prefs.setInt(_key('scan_count'), newValue);
  }

  @override
  Future<void> resetDaily() async {
    await _prefs.setInt(_key('scan_count'), 0);
    await _prefs.setString(_key('scan_date'), _today);
  }

  @override
  Future<bool> hasReachedLimit({required bool isPremium}) async {
    if (isPremium) return false;
    final used = await getTodayScanCount();
    return used >= ScanLimitRepository.dailyFreeLimit;
  }
}
