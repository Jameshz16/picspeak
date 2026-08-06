import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/features/flashcard_review/domain/srs_engine.dart';

void main() {
  group('SrsEngine.calculate()', () {
    test('new card (interval=0) + quality=3 (Easy) → interval 1', () {
      final result = SrsEngine.calculate(
        currentInterval: 0,
        currentEaseFactor: 2.5,
        quality: 3,
      );
      expect(result.interval, equals(1));
      expect(result.easeFactor, greaterThan(2.5));
    });

    test('new card + quality=2 (Good) → interval 1', () {
      final result = SrsEngine.calculate(
        currentInterval: 0,
        currentEaseFactor: 2.5,
        quality: 2,
      );
      expect(result.interval, equals(1));
    });

    test('new card + quality=1 (Hard) → interval 1, lower ease', () {
      final result = SrsEngine.calculate(
        currentInterval: 0,
        currentEaseFactor: 2.5,
        quality: 1,
      );
      expect(result.interval, equals(1));
      expect(result.easeFactor, lessThan(2.5));
    });

    test('new card + quality=0 (Again) → interval 1, lower ease', () {
      final result = SrsEngine.calculate(
        currentInterval: 0,
        currentEaseFactor: 2.5,
        quality: 0,
      );
      expect(result.interval, equals(1));
      expect(result.easeFactor, lessThan(2.5));
    });

    test('interval=1 + quality=3 → interval 3', () {
      final result = SrsEngine.calculate(
        currentInterval: 1,
        currentEaseFactor: 2.5,
        quality: 3,
      );
      expect(result.interval, equals(3));
    });

    test('interval=1 + quality=2 → interval 3', () {
      final result = SrsEngine.calculate(
        currentInterval: 1,
        currentEaseFactor: 2.5,
        quality: 2,
      );
      expect(result.interval, equals(3));
    });

    test('interval=3 + quality=3 → interval ~8', () {
      final result = SrsEngine.calculate(
        currentInterval: 3,
        currentEaseFactor: 2.5,
        quality: 3,
      );
      // 3 * 2.5 = 7.5, rounded = 8
      expect(result.interval, equals(8));
    });

    test('interval=10 + quality=2 → interval ~25', () {
      final result = SrsEngine.calculate(
        currentInterval: 10,
        currentEaseFactor: 2.5,
        quality: 2,
      );
      // 10 * 2.5 = 25
      expect(result.interval, equals(25));
    });

    test('wrong answer resets interval to 1', () {
      final result = SrsEngine.calculate(
        currentInterval: 30,
        currentEaseFactor: 2.5,
        quality: 0,
      );
      expect(result.interval, equals(1));
      expect(result.easeFactor, lessThan(2.5));
    });

    test('ease factor never goes below minimum', () {
      var ef = 2.5;
      // Simulate 10 consecutive failures
      for (var i = 0; i < 10; i++) {
        final result = SrsEngine.calculate(
          currentInterval: 1,
          currentEaseFactor: ef,
          quality: 0,
        );
        ef = result.easeFactor;
      }
      expect(ef, greaterThanOrEqualTo(SrsEngine.minEaseFactor));
    });

    test('next review date is in the future', () {
      final result = SrsEngine.calculate(
        currentInterval: 0,
        currentEaseFactor: 2.5,
        quality: 3,
      );
      expect(result.nextReview.isAfter(DateTime.now()), isTrue);
    });

    test('next review date matches interval', () {
      final result = SrsEngine.calculate(
        currentInterval: 0,
        currentEaseFactor: 2.5,
        quality: 3,
      );
      final expectedDate = DateTime.now().add(const Duration(days: 1));
      expect(
        result.nextReview.day,
        equals(expectedDate.day),
      );
    });
  });

  group('SrsEngine.isDue()', () {
    test('null nextReview → is due', () {
      expect(SrsEngine.isDue(null), isTrue);
    });

    test('past date → is due', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(SrsEngine.isDue(past), isTrue);
    });

    test('future date → not due', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(SrsEngine.isDue(future), isFalse);
    });

    test('now → not yet due (isAfter is strict)', () {
      // isDue uses isAfter (strict), so exactly "now" has not passed yet.
      expect(SrsEngine.isDue(DateTime.now()), isFalse);
    });
  });

  group('SrsEngine.nextReviewLabel()', () {
    test('null → "New"', () {
      expect(SrsEngine.nextReviewLabel(null), equals('New'));
    });

    test('past → "Due now"', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(SrsEngine.nextReviewLabel(past), equals('Due now'));
    });

    test('30 minutes → "in 30m"', () {
      final future = DateTime.now().add(const Duration(minutes: 30));
      expect(SrsEngine.nextReviewLabel(future), equals('in 30m'));
    });

    test('3+ hours → "in 3h"', () {
      // Use 3h30m so inHours truncation doesn't produce 'in 2h'
      // when a few nanoseconds elapse between DateTime.now() calls.
      final future = DateTime.now().add(const Duration(hours: 3, minutes: 30));
      expect(SrsEngine.nextReviewLabel(future), equals('in 3h'));
    });

    test('1 day → "tomorrow"', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(SrsEngine.nextReviewLabel(future), equals('tomorrow'));
    });

    test('5 days → "in 5 days"', () {
      // Add a few minutes cushion so inDays truncation doesn't produce 'in 4
      // days' when nanoseconds elapse between the two DateTime.now() calls.
      final future = DateTime.now().add(const Duration(days: 5, minutes: 30));
      expect(SrsEngine.nextReviewLabel(future), equals('in 5 days'));
    });

    test('14 days → "in 2 weeks"', () {
      final future = DateTime.now().add(const Duration(days: 14));
      expect(SrsEngine.nextReviewLabel(future), equals('in 2 weeks'));
    });
  });
}
