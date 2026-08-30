import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admob_service.dart';
import '../data/revenuecat_repository.dart';
import '../domain/premium_status.dart';
import '../domain/scan_limit_repository.dart';

/// Singleton RevenueCat repository.
final revenueCatRepositoryProvider = Provider<RevenueCatRepository>((ref) {
  return RevenueCatRepository();
});

/// AdMob service provider.
final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

/// Scan limit repository (SharedPreferences-backed).
final scanLimitRepositoryProvider = Provider<ScanLimitRepository>((ref) {
  throw UnimplementedError(
    'Override this provider with an initialized ScanLimitRepositoryImpl',
  );
});

/// Stream of the current premium status.
final premiumStatusProvider =
    FutureProvider<PremiumStatus>((ref) async {
  final repo = ref.watch(revenueCatRepositoryProvider);
  return repo.getPremiumStatus();
});

/// Whether the user is currently premium.
final isPremiumProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(premiumStatusProvider);
  return statusAsync.valueOrNull?.isPremium ?? false;
});

/// Reactive "today" key (yyyy-MM-dd).
///
/// Invalidates itself just after each midnight so providers that depend on it
/// (scan limits) re-read their daily counters without an app restart. When the
/// app is suspended across midnight, the pending timer fires on the next
/// resume, so a user blocked at 23:59 is unblocked after midnight.
final currentDayProvider = Provider<String>((ref) {
  final today = _dayKey(DateTime.now());

  Timer? timer;
  void scheduleNextMidnight() {
    timer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    timer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () => ref.invalidateSelf(),
    );
  }

  ref.onDispose(() => timer?.cancel());
  scheduleNextMidnight();

  return today;
});

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Remaining scans today. Returns -1 for premium (unlimited).
final remainingScansProvider = FutureProvider<int>((ref) async {
  ref.watch(currentDayProvider);
  final isPremium = ref.watch(isPremiumProvider);
  final repo = ref.watch(scanLimitRepositoryProvider);
  return repo.getRemainingScans(isPremium: isPremium);
});

/// Today's scan count.
final todayScanCountProvider = FutureProvider<int>((ref) async {
  ref.watch(currentDayProvider);
  final repo = ref.watch(scanLimitRepositoryProvider);
  return repo.getTodayScanCount();
});

/// Bonus scans granted by watching rewarded ads (resets daily with scan count).
final bonusScansProvider = StateProvider<int>((ref) => 0);
