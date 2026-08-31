import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/features/object_recognition/domain/template_phrases.dart';

void main() {
  group('generateTemplatePhrases', () {
    test('returns exactly 2 phrases', () {
      final phrases = generateTemplatePhrases('Cat', 'Gato');
      expect(phrases.length, 2);
    });

    test('first phrase contains the English label', () {
      final phrases = generateTemplatePhrases('Dog', 'Perro');
      expect(phrases[0].en, contains('Dog'));
    });

    test('first phrase contains the Spanish label', () {
      final phrases = generateTemplatePhrases('Dog', 'Perro');
      expect(phrases[0].es, contains('Perro'));
    });

    test('second phrase contains the English label', () {
      final phrases = generateTemplatePhrases('Bird', 'Pájaro');
      expect(phrases[1].en, contains('Bird'));
    });

    test('second phrase contains the Spanish label', () {
      final phrases = generateTemplatePhrases('Bird', 'Pájaro');
      expect(phrases[1].es, contains('Pájaro'));
    });

    test('works with multi-word labels', () {
      final phrases = generateTemplatePhrases('Coffee cup', 'Taza de café');
      expect(phrases[0].en, contains('Coffee cup'));
      expect(phrases[0].es, contains('Taza de café'));
    });
  });
}
