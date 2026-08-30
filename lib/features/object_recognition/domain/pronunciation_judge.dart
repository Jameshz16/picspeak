/// Outcome of a single pronunciation attempt.
enum PronunciationVerdict { excellent, good, needsWork, noSpeech }

/// Pure, side-effect-free judge that compares what the user said against
/// the target word. No external dependencies, so it is trivially
/// unit-testable.
class PronunciationJudge {
  const PronunciationJudge();

  /// Tolerance for a "close miss": a normalized Levenshtein distance at
  /// or below this share of the expected length counts as a near hit
  /// that still needs work.
  static const double _closeMissTolerance = 0.25;

  /// Minimum recognition confidence for a partial (contains) match to be
  /// graded [PronunciationVerdict.good]. Below this it degrades to
  /// [PronunciationVerdict.needsWork].
  static const double _minGoodConfidence = 0.4;

  /// Minimum length of a normalized utterance that counts as speech.
  static const int _minSpeechLength = 2;

  /// Matches one or more trailing punctuation characters.
  static final RegExp _trailingPunctuation = RegExp(r'[.!?,;:]+$');

  /// Matches any run of whitespace (space, tab, newline).
  static final RegExp _whitespace = RegExp(r'\s+');

  PronunciationVerdict judge({
    required String expected,
    required String recognized,
    double? confidence,
  }) {
    final normExpected = _normalize(expected);
    final normRecognized = _normalize(recognized);

    // Nothing usable was captured: empty or too short to evaluate.
    if (normExpected.isEmpty || normRecognized.length < _minSpeechLength) {
      return PronunciationVerdict.noSpeech;
    }

    // Exact match after normalization is a perfect pronunciation.
    if (normExpected == normRecognized) {
      return PronunciationVerdict.excellent;
    }

    // One side contains the other as a standalone word → partial match.
    if (_containsWord(normExpected, normRecognized) ||
        _containsWord(normRecognized, normExpected)) {
      return _hasLowConfidence(confidence)
          ? PronunciationVerdict.needsWork
          : PronunciationVerdict.good;
    }

    // Similarity via Levenshtein, normalized to the expected length.
    final normalizedDistance =
        _levenshtein(normExpected, normRecognized) / normExpected.length;
    if (normalizedDistance <= _closeMissTolerance) {
      // A close miss: the user said something recognizable but not exact.
      return PronunciationVerdict.needsWork;
    }

    // A miss beyond the tolerance produces no usable match; the attempt
    // fails as if no speech was captured (the user is asked to retry).
    return PronunciationVerdict.noSpeech;
  }

  /// Lowercases, trims, collapses whitespace and strips trailing
  /// punctuation so that "Dog!" and " dog  " both normalize to "dog".
  String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(_whitespace, ' ')
        .replaceAll(_trailingPunctuation, '')
        .trim();
  }

  /// True when [word] appears inside [container] surrounded by word
  /// boundaries (start, whitespace, or end).
  bool _containsWord(String container, String word) {
    final escaped = RegExp.escape(word);
    return RegExp('(^|\\s)$escaped(\$|\\s)').hasMatch(container);
  }

  bool _hasLowConfidence(double? confidence) =>
      confidence != null && confidence < _minGoodConfidence;

  /// Classic dynamic-programming Levenshtein distance between [a] and
  /// [b]. Implemented here (instead of pulling in a package) to keep the
  /// domain layer dependency-free.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final substitutionCost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = _min3(
          curr[j - 1] + 1, // insertion
          prev[j] + 1, // deletion
          prev[j - 1] + substitutionCost, // substitution
        );
      }
      prev = List<int>.of(curr);
    }
    return curr[b.length];
  }

  int _min3(int a, int b, int c) {
    final min = a < b ? a : b;
    return min < c ? min : c;
  }
}
