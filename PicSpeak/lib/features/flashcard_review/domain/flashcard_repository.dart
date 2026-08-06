import '../../object_recognition/domain/recognized_word.dart';

abstract class FlashcardRepository {
  Future<void> save(RecognizedWord word);
  Future<List<RecognizedWord>> loadAll();
  Future<bool> exists(String enLabel);
  Future<void> remove(String enLabel);

  /// Get cards that are due for review (nextReview is null or past).
  Future<List<RecognizedWord>> getDueCards();

  /// Update a card's SRS data after a review session.
  Future<void> updateSrs({
    required String enLabel,
    required int interval,
    required double easeFactor,
    required DateTime nextReview,
  });

  /// Get the count of cards due for review.
  Future<int> getDueCount();
}
