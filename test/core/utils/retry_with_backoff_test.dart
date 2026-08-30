import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/core/utils/retry_with_backoff.dart';

void main() {
  group('retryWithBackoff', () {
    test('returns result on first attempt (no retry)', () async {
      var calls = 0;
      final result = await retryWithBackoff<int>(
        () async {
          calls++;
          return 42;
        },
        maxAttempts: 3,
        delayOf: (_) => Duration.zero,
      );
      expect(result, 42);
      expect(calls, 1);
    });

    test('retries on failure and succeeds on second attempt', () async {
      var calls = 0;
      final result = await retryWithBackoff<String>(
        () async {
          calls++;
          if (calls == 1) throw Exception('transient');
          return 'ok';
        },
        maxAttempts: 3,
        delayOf: (_) => Duration.zero,
      );
      expect(result, 'ok');
      expect(calls, 2);
    });

    test('retries up to maxAttempts then throws', () async {
      var calls = 0;
      Object? caughtError;
      try {
        await retryWithBackoff<void>(
          () async {
            calls++;
            throw Exception('permanent failure');
          },
          maxAttempts: 3,
          delayOf: (_) => const Duration(milliseconds: 1),
        );
      } catch (e) {
        caughtError = e;
      }
      expect(caughtError, isA<Exception>());
      expect(calls, 3);
    });

    test('returns on attempt exactly at maxAttempts', () async {
      var calls = 0;
      final result = await retryWithBackoff<int>(
        () async {
          calls++;
          if (calls < 3) throw Exception('not yet');
          return 99;
        },
        maxAttempts: 3,
        delayOf: (_) => Duration.zero,
      );
      expect(result, 99);
      expect(calls, 3);
    });

    test('delayOf is called with correct attempt numbers', () async {
      final delays = <int>[];
      var calls = 0;

      await retryWithBackoff<void>(
        () async {
          calls++;
          if (calls <= 2) throw Exception('fail');
        },
        maxAttempts: 3,
        delayOf: (attempt) {
          delays.add(attempt);
          return Duration.zero;
        },
      );

      // delayOf called for attempt 1 (before retry 2) and attempt 2 (before retry 3)
      expect(delays, [1, 2]);
    });

    test('respects custom delay (backoff timing)', () async {
      var calls = 0;
      final sw = Stopwatch()..start();

      await retryWithBackoff<void>(
        () async {
          calls++;
          if (calls <= 2) throw Exception('fail');
        },
        maxAttempts: 3,
        delayOf: (_) => const Duration(milliseconds: 50),
      );

      sw.stop();
      // Should have taken at least 100ms (2 delays of 50ms each)
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(100));
      expect(calls, 3);
    });

    test('throws last exception when all attempts fail', () async {
      try {
        await retryWithBackoff<void>(
          () async => throw StateError('last error'),
          maxAttempts: 2,
          delayOf: (_) => Duration.zero,
        );
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<StateError>());
        expect((e as StateError).message, 'last error');
      }
    });
  });
}
