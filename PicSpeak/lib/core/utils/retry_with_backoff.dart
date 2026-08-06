/// Retries [operation] up to [maxAttempts] times with exponential backoff.
///
/// [delayOf] returns the delay before attempt `i` (1-indexed). Defaults to
/// 1 s, 2 s, 4 s … (exponential, base 2, starting at 1 s).
///
/// Returns the first successful result. If all attempts fail, throws the
/// last exception.
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration Function(int attempt) delayOf = _defaultDelay,
}) async {
  assert(maxAttempts >= 1, 'maxAttempts must be >= 1');

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      await Future<void>.delayed(delayOf(attempt));
    }
  }

  // Unreachable but satisfies the analyzer.
  throw StateError('retryWithBackoff: exhausted');
}

Duration _defaultDelay(int attempt) {
  // 1 s, 2 s, 4 s … (2^(attempt-1) seconds)
  return Duration(seconds: 1 << (attempt - 1));
}
