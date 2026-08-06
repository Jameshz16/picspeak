import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../flashcard_review/data/flashcard_providers.dart';
import '../../flashcard_review/domain/flashcard_repository.dart';
import '../../word_history/data/history_providers.dart';
import '../../word_history/domain/history_repository.dart';
import '../domain/learning_stats.dart';

class StatsRepository {
  final SharedPreferences _prefs;
  static const _streakKey = 'study_streak';
  static const _lastStudyKey = 'last_study_date';
  static const _reviewedTodayKey = 'reviewed_today_count';
  static const _reviewedTodayDateKey = 'reviewed_today_date';

  StatsRepository(this._prefs);

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

    final lastStudy = _prefs.getString(_lastStudyKey);
    if (lastStudy == today) return; // Only guard streak update

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    int streak = _prefs.getInt(_streakKey) ?? 0;

    if (lastStudy == yesterday) {
      streak++;
    } else {
      streak = 1;
    }

    _prefs.setInt(_streakKey, streak);
    _prefs.setString(_lastStudyKey, today);
  }

  int _updateStreak() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastStudy = _prefs.getString(_lastStudyKey);

    if (lastStudy == today) {
      return _prefs.getInt(_streakKey) ?? 0;
    }

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    if (lastStudy == yesterday) {
      return _prefs.getInt(_streakKey) ?? 0;
    }

    return 0;
  }

  int _getReviewedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = _prefs.getString(_reviewedTodayDateKey);
    if (savedDate != today) return 0;
    return _prefs.getInt(_reviewedTodayKey) ?? 0;
  }

  void _addReviewedToday(int count) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = _prefs.getString(_reviewedTodayDateKey);
    int current = 0;
    if (savedDate == today) {
      current = _prefs.getInt(_reviewedTodayKey) ?? 0;
    }
    _prefs.setInt(_reviewedTodayKey, current + count);
    _prefs.setString(_reviewedTodayDateKey, today);
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
