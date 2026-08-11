import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/current_user.dart';
import '../../flashcard_review/data/flashcard_providers.dart';
import '../../flashcard_review/domain/flashcard_repository.dart';
import '../../word_history/data/history_providers.dart';
import '../../word_history/domain/history_repository.dart';
import '../domain/learning_stats.dart';

class StatsRepository {
  final SharedPreferences _prefs;

  StatsRepository(this._prefs);

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  /// Reads a user-scoped string with a one-time migration from the legacy
  /// unscoped key. Once migrated the legacy key is removed so a future
  /// different user on the same device never sees the previous user's data.
  String? _getStringWithLegacy(String base) {
    final scoped = _prefs.getString(_key(base));
    if (scoped != null) return scoped;
    if (currentUserId.isEmpty) return null;
    final legacy = _prefs.getString(base);
    if (legacy != null) {
      _prefs.setString(_key(base), legacy);
      _prefs.remove(base);
      return legacy;
    }
    return null;
  }

  /// Reads a user-scoped int with a one-time migration from the legacy
  /// unscoped key. Once migrated the legacy key is removed so a future
  /// different user on the same device never sees the previous user's data.
  int? _getIntWithLegacy(String base) {
    final scoped = _prefs.getInt(_key(base));
    if (scoped != null) return scoped;
    if (currentUserId.isEmpty) return null;
    final legacy = _prefs.getInt(base);
    if (legacy != null) {
      _prefs.setInt(_key(base), legacy);
      _prefs.remove(base);
      return legacy;
    }
    return null;
  }

  /// Compute stats from flashcard + history data.
  Future<LearningStats> computeStats({
    required FlashcardRepository flashcardRepo,
    required HistoryRepository historyRepo,
  }) async {
    final favorites = await flashcardRepo.loadAll();
    final history = await historyRepo.loadAll();
    final dueToday = await flashcardRepo.getDueCount();

    // Count mastered (interval >= 21 days)
    final mastered = favorites.where((w) => w.interval >= 21).length;

    // Update streak
    final streak = _updateStreak();

    // Read today's reviewed count
    final reviewedToday = _getReviewedToday();

    return LearningStats(
      totalFavorites: favorites.length,
      totalScanned: history.length,
      dueToday: dueToday,
      reviewedToday: reviewedToday,
      masteredCount: mastered,
      streakDays: streak,
    );
  }

  /// Call after each review session to update streak and reviewed count.
  void recordStudySession({int reviewedCount = 0}) {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Always accumulate reviewed count, even for same-day sessions
    _addReviewedToday(reviewedCount);

    final lastStudy = _getStringWithLegacy('last_study_date');
    if (lastStudy == today) return;

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    int streak = _getIntWithLegacy('study_streak') ?? 0;

    if (lastStudy == yesterday) {
      streak++;
    } else {
      streak = 1;
    }

    _prefs.setInt(_key('study_streak'), streak);
    _prefs.setString(_key('last_study_date'), today);
  }

  int _updateStreak() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastStudy = _getStringWithLegacy('last_study_date');

    if (lastStudy == today) {
      return _getIntWithLegacy('study_streak') ?? 0;
    }

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    if (lastStudy == yesterday) {
      return _getIntWithLegacy('study_streak') ?? 0;
    }

    return 0;
  }

  int _getReviewedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = _getStringWithLegacy('reviewed_today_date');
    if (savedDate != today) return 0;
    return _getIntWithLegacy('reviewed_today_count') ?? 0;
  }

  void _addReviewedToday(int count) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = _getStringWithLegacy('reviewed_today_date');
    int current = 0;
    if (savedDate == today) {
      current = _getIntWithLegacy('reviewed_today_count') ?? 0;
    }
    _prefs.setInt(_key('reviewed_today_count'), current + count);
    _prefs.setString(_key('reviewed_today_date'), today);
  }
}

final statsRepositoryProvider = FutureProvider<StatsRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return StatsRepository(prefs);
});

final learningStatsProvider = FutureProvider<LearningStats>((ref) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  final flashcardRepo = ref.watch(flashcardRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);
  return repo.computeStats(
    flashcardRepo: flashcardRepo,
    historyRepo: historyRepo,
  );
});
