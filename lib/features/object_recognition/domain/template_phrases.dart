import '../../../core/data/phrase_repository.dart';

/// Generates simple template-based phrases for any noun.
///
/// Used as a fallback when no curated phrases exist in the JSON asset.
/// Templates are designed for A1-A2 learners and work with any noun
/// without gender detection.
List<PhrasePair> generateTemplatePhrases(String enLabel, String esLabel) {
  return [
    PhrasePair(
      en: 'I can see a $enLabel.',
      es: 'Puedo ver $esLabel.',
    ),
    PhrasePair(
      en: 'Look at the $enLabel.',
      es: 'Mira $esLabel.',
    ),
  ];
}
