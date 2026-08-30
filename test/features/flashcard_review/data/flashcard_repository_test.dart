import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picspeak/features/flashcard_review/data/flashcard_repository_impl.dart';
import 'package:picspeak/features/object_recognition/domain/recognized_word.dart';

void main() {
  group('FlashcardRepository', () {
    late FlashcardRepositoryImpl repository;
    late SharedPreferences prefs;

    final word1 = RecognizedWord(
      enLabel: 'dog',
      esLabel: 'perro',
      confidence: 0.95,
      photoPath: '/path/to/photo1.jpg',
      timestamp: DateTime(2024, 1, 1, 10, 0),
    );

    final word2 = RecognizedWord(
      enLabel: 'cat',
      esLabel: 'gato',
      confidence: 0.88,
      photoPath: '/path/to/photo2.jpg',
      timestamp: DateTime(2024, 1, 1, 10, 30),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = FlashcardRepositoryImpl(prefs);
    });

    test('save stores a new flashcard', () async {
      await repository.save(word1);
      final cards = await repository.loadAll();
      expect(cards.length, equals(1));
      expect(cards.first.enLabel, equals('dog'));
      expect(cards.first.esLabel, equals('perro'));
    });

    test('loadAll returns empty list when nothing is saved', () async {
      final cards = await repository.loadAll();
      expect(cards, isEmpty);
    });

    test('deduplication: saving same enLabel twice stores only one', () async {
      await repository.save(word1);
      await repository.save(word1);
      final cards = await repository.loadAll();
      expect(cards.length, equals(1));
    });

    test('remove deletes a flashcard by enLabel', () async {
      await repository.save(word1);
      await repository.save(word2);
      await repository.remove('dog');
      final cards = await repository.loadAll();
      expect(cards.length, equals(1));
      expect(cards.first.enLabel, equals('cat'));
    });

    test('exists returns true for saved label and false otherwise', () async {
      await repository.save(word1);
      expect(await repository.exists('dog'), isTrue);
      expect(await repository.exists('cat'), isFalse);
    });

    test('save multiple unique words stores all', () async {
      await repository.save(word1);
      await repository.save(word2);
      final cards = await repository.loadAll();
      expect(cards.length, equals(2));
      expect(cards.map((w) => w.enLabel).toList(), containsAll(['dog', 'cat']));
    });
  });
}
