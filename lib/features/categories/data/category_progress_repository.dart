import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/label_map_repository.dart';
import '../../../core/utils/current_user.dart';
import '../../word_history/data/history_providers.dart';
import '../../word_history/domain/history_repository.dart';

/// Tracks category progression based on scanned words.
///
/// A category badge is "unlocked" when the user has scanned at least
/// [badgeThreshold] unique words from that category.
class CategoryProgressRepository {
  final SharedPreferences _prefs;
  final LabelMapRepository _labelMap;
  final HistoryRepository _historyRepo;

  static const int badgeThreshold = 5; // Words needed to unlock badge

  CategoryProgressRepository(this._prefs, this._labelMap, this._historyRepo);

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  /// Get progress for all categories.
  Future<List<CategoryProgress>> getAllProgress() async {
    final history = await _historyRepo.loadAll();
    final categories = _labelMap.getCategories();
    final scannedWords = history
        .map((w) => w.enLabel.toLowerCase())
        .toSet();

    final List<CategoryProgress> result = [];

    for (final cat in categories) {
      final wordsInCategory = _labelMap.getWordsInCategory(cat.id);
      final totalWords = wordsInCategory.length;
      
      if (totalWords == 0) continue;

      // Count unique scanned words in this category
      int scannedCount = 0;
      for (final entry in wordsInCategory) {
        if (scannedWords.contains(entry.key.toLowerCase())) {
          scannedCount++;
        }
      }

      final percent = totalWords > 0 ? (scannedCount / totalWords * 100).round() : 0;
      final isUnlocked = scannedCount >= badgeThreshold;
      final isCompleted = scannedCount >= totalWords;

      // Check if badge was previously unlocked (for celebration)
      final wasUnlocked = _prefs.getBool(_key('badge_${cat.id}')) ?? false;
      if (isUnlocked && !wasUnlocked) {
        await _prefs.setBool(_key('badge_${cat.id}'), true);
      }

      result.add(CategoryProgress(
        categoryId: cat.id,
        categoryName: cat.nameEs,
        categoryIcon: cat.icon,
        scannedWords: scannedCount,
        totalWords: totalWords,
        percent: percent,
        isUnlocked: isUnlocked,
        isCompleted: isCompleted,
        isNewUnlock: isUnlocked && !wasUnlocked,
      ));
    }

    // Sort: unlocked first, then by percent descending
    result.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      return b.percent.compareTo(a.percent);
    });

    return result;
  }

  /// Get progress for a specific category.
  Future<CategoryProgress> getCategoryProgress(String categoryId) async {
    final all = await getAllProgress();
    return all.firstWhere(
      (p) => p.categoryId == categoryId,
      orElse: () => CategoryProgress.empty(categoryId),
    );
  }

  /// Get total stats across all categories.
  Future<CategoryStats> getStats() async {
    final all = await getAllProgress();
    final unlocked = all.where((p) => p.isUnlocked).length;
    final completed = all.where((p) => p.isCompleted).length;
    final totalWords = all.fold<int>(0, (sum, p) => sum + p.scannedWords);

    return CategoryStats(
      totalCategories: all.length,
      unlockedBadges: unlocked,
      completedCategories: completed,
      totalWordsScanned: totalWords,
    );
  }

  /// Reset all badge unlocks (for testing).
  Future<void> resetAll() async {
    final categories = _labelMap.getCategories();
    for (final cat in categories) {
      await _prefs.remove(_key('badge_${cat.id}'));
    }
  }
}

/// Progress data for a single category.
class CategoryProgress {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final int scannedWords;
  final int totalWords;
  final int percent;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isNewUnlock;

  const CategoryProgress({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.scannedWords,
    required this.totalWords,
    required this.percent,
    required this.isUnlocked,
    required this.isCompleted,
    this.isNewUnlock = false,
  });

  factory CategoryProgress.empty(String id) => CategoryProgress(
        categoryId: id,
        categoryName: '',
        categoryIcon: 'category',
        scannedWords: 0,
        totalWords: 0,
        percent: 0,
        isUnlocked: false,
        isCompleted: false,
      );

  /// Get a narrative message based on progress.
  String get narrativeMessage {
    if (isCompleted) {
      return '¡Completaste $categoryName!';
    }
    if (isUnlocked) {
      final remaining = totalWords - scannedWords;
      return '¡Sello desbloqueado! Faltan $remaining palabras';
    }
    final needed = CategoryProgressRepository.badgeThreshold - scannedWords;
    if (needed <= 0) {
      return '¡Casi! Descubre más palabras';
    }
    return 'Descubre $needed palabras más para el sello';
  }

  /// Get the icon data for this category.
  String get iconData => categoryIcon;
}

/// Aggregate stats across all categories.
class CategoryStats {
  final int totalCategories;
  final int unlockedBadges;
  final int completedCategories;
  final int totalWordsScanned;

  const CategoryStats({
    required this.totalCategories,
    required this.unlockedBadges,
    required this.completedCategories,
    required this.totalWordsScanned,
  });

  String get narrativeMessage {
    if (completedCategories > 0) {
      return '$completedCategories categorías dominadas';
    }
    if (unlockedBadges > 0) {
      return '$unlockedBadges sellos desbloqueados';
    }
    return 'Explora categorías para desbloquear sellos';
  }
}

/// Provider for the CategoryProgressRepository.
final categoryProgressRepositoryProvider = FutureProvider<CategoryProgressRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final labelMap = await ref.watch(labelMapProvider.future);
  final historyRepo = ref.watch(historyRepositoryProvider);
  return CategoryProgressRepository(prefs, labelMap, historyRepo);
});

/// Provider for all category progress.
final categoryProgressProvider = FutureProvider<List<CategoryProgress>>((ref) async {
  final repo = await ref.watch(categoryProgressRepositoryProvider.future);
  return repo.getAllProgress();
});

/// Provider for aggregate category stats.
final categoryStatsProvider = FutureProvider<CategoryStats>((ref) async {
  final repo = await ref.watch(categoryProgressRepositoryProvider.future);
  return repo.getStats();
});
