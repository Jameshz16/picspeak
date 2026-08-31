import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/core/data/phrase_repository.dart';

class _TestPhraseRepository implements PhraseRepository {
  final Map<String, List<PhrasePair>> _phrases;

  _TestPhraseRepository(this._phrases);

  @override
  List<PhrasePair>? getPhrases(String enLabel) => _phrases[enLabel];
}

void main() {
  group('PhraseRepository.getPhrases', () {
    test('returns phrase pairs for a known word', () {
      final repo = _TestPhraseRepository({
        'Cat': [
          const PhrasePair(
            en: 'The cat is sleeping.',
            es: 'El gato está durmiendo.',
          ),
          const PhrasePair(
            en: 'I have a cat.',
            es: 'Tengo un gato.',
          ),
        ],
      });

      final result = repo.getPhrases('Cat');
      expect(result, isNotNull);
      expect(result, hasLength(2));
      expect(result![0].en, equals('The cat is sleeping.'));
      expect(result[0].es, equals('El gato está durmiendo.'));
      expect(result[1].en, equals('I have a cat.'));
      expect(result[1].es, equals('Tengo un gato.'));
    });

    test('returns null for a word without phrases', () {
      final repo = _TestPhraseRepository({
        'Cat': [
          const PhrasePair(en: 'A', es: 'B'),
        ],
      });

      expect(repo.getPhrases('Dog'), isNull);
    });

    test('returns null for empty repository', () {
      final repo = _TestPhraseRepository({});

      expect(repo.getPhrases('Cat'), isNull);
    });

    test('lookup is case-sensitive', () {
      final repo = _TestPhraseRepository({
        'Cat': [const PhrasePair(en: 'A', es: 'B')],
      });

      expect(repo.getPhrases('Cat'), isNotNull);
      expect(repo.getPhrases('cat'), isNull);
      expect(repo.getPhrases('CAT'), isNull);
    });

    test('handles word with spaces in key', () {
      final repo = _TestPhraseRepository({
        'Ice cream': [
          const PhrasePair(en: 'I like ice cream.', es: 'Me gusta el helado.'),
        ],
      });

      final result = repo.getPhrases('Ice cream');
      expect(result, isNotNull);
      expect(result, hasLength(1));
    });
  });

  group('PhrasePair', () {
    test('stores en and es fields', () {
      const pair = PhrasePair(en: 'Hello', es: 'Hola');
      expect(pair.en, equals('Hello'));
      expect(pair.es, equals('Hola'));
    });
  });
}
