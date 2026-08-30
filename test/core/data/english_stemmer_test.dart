import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/core/data/english_stemmer.dart';

void main() {
  group('EnglishStemmer', () {
    late EnglishStemmer stemmer;

    setUp(() {
      stemmer = EnglishStemmer();
    });

    group('stem()', () {
      test('strips -ing suffix', () {
        expect(stemmer.stem('running'), equals('runn'));
        expect(stemmer.stem('walking'), equals('walk'));
        expect(stemmer.stem('swimming'), equals('swimm'));
        expect(stemmer.stem('fishing'), equals('fish'));
      });

      test('strips -ed suffix', () {
        expect(stemmer.stem('walked'), equals('walk'));
        expect(stemmer.stem('played'), equals('play'));
        expect(stemmer.stem('jumped'), equals('jump'));
      });

      test('strips -s / -es suffix', () {
        expect(stemmer.stem('dogs'), equals('dog'));
        expect(stemmer.stem('cats'), equals('cat'));
        expect(stemmer.stem('boxes'), equals('box'));
        expect(stemmer.stem('buses'), equals('bus'));
      });

      test('strips -er / -est suffix', () {
        expect(stemmer.stem('taller'), equals('tall'));
        expect(stemmer.stem('tallest'), equals('tall'));
        expect(stemmer.stem('bigger'), equals('bigg'));
        expect(stemmer.stem('running'), equals('runn'));
      });

      test('strips -ly suffix', () {
        expect(stemmer.stem('quickly'), equals('quick'));
        expect(stemmer.stem('slowly'), equals('slow'));
      });

      test('handles irregular plurals', () {
        expect(stemmer.stem('children'), equals('child'));
        expect(stemmer.stem('mice'), equals('mouse'));
        expect(stemmer.stem('geese'), equals('goose'));
        expect(stemmer.stem('men'), equals('man'));
        expect(stemmer.stem('women'), equals('woman'));
        expect(stemmer.stem('teeth'), equals('tooth'));
        expect(stemmer.stem('feet'), equals('foot'));
        expect(stemmer.stem('people'), equals('person'));
      });

      test('returns lowercase original for short words', () {
        expect(stemmer.stem('cat'), equals('cat'));
        expect(stemmer.stem('dog'), equals('dog'));
        expect(stemmer.stem('hi'), equals('hi'));
      });

      test('returns lowercase for unknown words', () {
        expect(stemmer.stem('xyz'), equals('xyz'));
        expect(stemmer.stem('Hello'), equals('hello'));
      });

      test('preserves at least 3 characters', () {
        // "es" suffix on a 5-char word should leave 3 chars
        expect(stemmer.stem('plates'), equals('plat'));
        expect(stemmer.stem('cakes'), equals('cak'));
      });
    });

    group('stemVariants()', () {
      test('returns multiple candidates', () {
        final variants = stemmer.stemVariants('running');
        expect(variants, contains('running'));
        expect(variants, contains('runn'));
      });

      test('includes irregular form', () {
        final variants = stemmer.stemVariants('children');
        expect(variants, contains('children'));
        expect(variants, contains('child'));
      });

      test('single-char word returns only itself', () {
        final variants = stemmer.stemVariants('a');
        expect(variants, equals(['a']));
      });
    });
  });
}
