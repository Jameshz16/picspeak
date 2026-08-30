import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/features/object_recognition/domain/pronunciation_judge.dart';

void main() {
  const judge = PronunciationJudge();

  group('PronunciationJudge', () {
    group('excellent', () {
      test('exact match', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'dog'),
          PronunciationVerdict.excellent,
        );
      });

      test('case and trailing punctuation are normalized', () {
        expect(
          judge.judge(expected: 'Dog', recognized: 'dog!'),
          PronunciationVerdict.excellent,
        );
        expect(
          judge.judge(expected: 'dog', recognized: '  DOG.  '),
          PronunciationVerdict.excellent,
        );
      });

      test('exact match stays excellent even with low confidence', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'dog', confidence: 0.2),
          PronunciationVerdict.excellent,
        );
      });
    });

    group('good', () {
      test('recognized text contains the expected word', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'i saw a dog'),
          PronunciationVerdict.good,
        );
      });

      test('expected text contains the recognized word', () {
        expect(
          judge.judge(expected: 'stop sign', recognized: 'stop'),
          PronunciationVerdict.good,
        );
      });

      test('confidence is ignored when missing', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'the dog'),
          PronunciationVerdict.good,
        );
      });

      test('word boundaries matter (doghouse is not dog)', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'doghouse'),
          PronunciationVerdict.noSpeech,
        );
      });
    });

    group('needsWork', () {
      test('close miss via Levenshtein', () {
        expect(
          judge.judge(expected: 'hello', recognized: 'hallo'),
          PronunciationVerdict.needsWork,
        );
      });

      test('partial match with low confidence degrades from good', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'the dog', confidence: 0.3),
          PronunciationVerdict.needsWork,
        );
      });

      test('partial match with good confidence stays good', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'the dog', confidence: 0.9),
          PronunciationVerdict.good,
        );
      });
    });

    group('noSpeech', () {
      test('empty recognized text', () {
        expect(
          judge.judge(expected: 'dog', recognized: ''),
          PronunciationVerdict.noSpeech,
        );
      });

      test('whitespace-only recognized text', () {
        expect(
          judge.judge(expected: 'dog', recognized: '   '),
          PronunciationVerdict.noSpeech,
        );
      });

      test('single character is too short', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'd'),
          PronunciationVerdict.noSpeech,
        );
      });

      test('unrelated word is too far from the target', () {
        expect(
          judge.judge(expected: 'dog', recognized: 'cat'),
          PronunciationVerdict.noSpeech,
        );
      });
    });
  });
}
