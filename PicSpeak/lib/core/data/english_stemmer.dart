/// Basic English suffix-stripping stemmer.
///
/// Not a full Porter stemmer — just enough to map common ML Kit label
/// variants ("Running" → "Run", "Dogs" → "Dog") back to dictionary roots.
class EnglishStemmer {
  /// Suffixes ordered longest-first so greedy match wins.
  static const _suffixes = [
    // 5 letter suffixes
    'ation',
    // 4 letter suffixes
    'ment',
    'ness',
    'ible',
    'able',
    'tion',
    'ally',
    // 3 letter suffixes
    'ful',
    'ing',
    'ous',
    'ive',
    'ish',
    'ers',
    'est',
    // 2 letter suffixes
    'ly',
    'ed',
    'er',
    'es',
    'en',
    // 1 letter suffix — simple plurals (dogs→dog, cats→cat)
    's',
  ];

  /// Short irregular plurals / forms that don't follow suffix rules.
  static const _irregulars = {
    'children': 'child',
    'mice': 'mouse',
    'geese': 'goose',
    'men': 'man',
    'women': 'woman',
    'teeth': 'tooth',
    'feet': 'foot',
    'people': 'person',
    'oxen': 'ox',
    'criteria': 'criterion',
    'phenomena': 'phenomenon',
    'fungi': 'fungus',
    'cacti': 'cactus',
    'nuclei': 'nucleus',
    'stimuli': 'stimulus',
    'alumni': 'alumnus',
    'syllabi': 'syllabus',
    'bacteria': 'bacterium',
  };

  /// Returns the stemmed form of [word], or the original word if no
  /// stripping was possible.
  String stem(String word) {
    final lower = word.toLowerCase();

    // Check irregulars first
    if (_irregulars.containsKey(lower)) {
      return _irregulars[lower]!;
    }

    // Try suffix stripping
    for (final suffix in _suffixes) {
      if (lower.length > suffix.length + 2 && lower.endsWith(suffix)) {
        final candidate = lower.substring(0, lower.length - suffix.length);
        // Avoid over-stripping: keep at least 3 chars
        if (candidate.length >= 3) {
          return candidate;
        }
      }
    }

    return lower;
  }

  /// Try multiple stem variations and return all unique candidates.
  List<String> stemVariants(String word) {
    final lower = word.toLowerCase();
    final variants = <String>{lower};

    // Irregular
    if (_irregulars.containsKey(lower)) {
      variants.add(_irregulars[lower]!);
    }

    // Suffix stripping
    for (final suffix in _suffixes) {
      if (lower.length > suffix.length + 2 && lower.endsWith(suffix)) {
        final candidate = lower.substring(0, lower.length - suffix.length);
        if (candidate.length >= 3) {
          variants.add(candidate);
        }
      }
    }

    return variants.toList();
  }
}
