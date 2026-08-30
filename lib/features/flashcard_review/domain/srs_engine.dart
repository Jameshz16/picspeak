/// Simplified SM-2 spaced repetition algorithm.
///
/// Based on the SuperMemo SM-2 algorithm, adapted for vocabulary learning.
/// Quality ratings:
///   0 = Again (complete blackout)
///   1 = Hard (incorrect, but remembered after seeing answer)
///   2 = Good (correct with serious difficulty)
///   3 = Easy (correct with minor hesitation)
class SrsEngine {
  /// Default ease factor for new cards.
  static const defaultEaseFactor = 2.5;

  /// Minimum ease factor to prevent intervals from shrinking too much.
  static const minEaseFactor = 1.3;

  /// Calculate the next review interval and ease factor.
  ///
  /// [currentInterval] — current interval in days (0 for new cards).
  /// [currentEaseFactor] — current ease factor.
  /// [quality] — user rating 0-3.
  ///
  /// Returns a record with the new interval, ease factor, and next review date.
  static SrsResult calculate({
    required int currentInterval,
    required double currentEaseFactor,
    required int quality,
  }) {
    assert(quality >= 0 && quality <= 3, 'Quality must be 0-3');

    double newEaseFactor = currentEaseFactor;
    int newInterval;

    if (quality >= 2) {
      // Correct response — increase interval
      if (currentInterval == 0) {
        // First review: 1 day
        newInterval = 1;
      } else if (currentInterval == 1) {
        // Second review: 3 days
        newInterval = 3;
      } else {
        // Subsequent: multiply by ease factor
        newInterval = (currentInterval * currentEaseFactor).round();
      }

      // Adjust ease factor
      newEaseFactor = currentEaseFactor +
          (0.1 - (3 - quality) * (0.08 + (3 - quality) * 0.02));
    } else {
      // Incorrect — reset to 1 day
      newInterval = 1;
      // Decrease ease factor
      newEaseFactor = currentEaseFactor - 0.2;
    }

    // Clamp ease factor
    if (newEaseFactor < minEaseFactor) {
      newEaseFactor = minEaseFactor;
    }

    final nextReview = DateTime.now().add(Duration(days: newInterval));

    return SrsResult(
      interval: newInterval,
      easeFactor: newEaseFactor,
      nextReview: nextReview,
    );
  }

  /// Check if a card is due for review.
  static bool isDue(DateTime? nextReview) {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview);
  }

  /// Get a human-readable label for the next review time.
  static String nextReviewLabel(DateTime? nextReview) {
    if (nextReview == null) return 'New';
    final now = DateTime.now();
    final diff = nextReview.difference(now);
    if (diff.isNegative) return 'Due now';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    if (diff.inDays == 1) return 'tomorrow';
    if (diff.inDays < 7) return 'in ${diff.inDays} days';
    if (diff.inDays < 30) return 'in ${(diff.inDays / 7).round()} weeks';
    return 'in ${(diff.inDays / 30).round()} months';
  }
}

/// Result of an SRS calculation.
class SrsResult {
  final int interval;
  final double easeFactor;
  final DateTime nextReview;

  const SrsResult({
    required this.interval,
    required this.easeFactor,
    required this.nextReview,
  });
}
