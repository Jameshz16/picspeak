/// Aggregated learning statistics for the user.
class LearningStats {
  final int totalFavorites;
  final int totalScanned;
  final int dueToday;
  final int reviewedToday;
  final int masteredCount; // interval >= 21 days
  final int streakDays;
  final Map<String, int> wordsByCategory;

  const LearningStats({
    required this.totalFavorites,
    required this.totalScanned,
    required this.dueToday,
    required this.reviewedToday,
    required this.masteredCount,
    required this.streakDays,
    this.wordsByCategory = const {},
  });

  double get masteryPercent =>
      totalFavorites > 0 ? masteredCount / totalFavorites * 100 : 0;

  int get learningCount => totalFavorites - masteredCount - dueToday;
}
