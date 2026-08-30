import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picspeak/features/word_history/data/history_repository_impl.dart';
import 'package:picspeak/features/object_recognition/domain/recognized_word.dart';

void main() {
  group('HistoryRepository', () {
    late HistoryRepositoryImpl repository;
    late SharedPreferences prefs;

    final word1 = RecognizedWord(
      enLabel: 'dog',
      esLabel: 'perro',
      confidence: 0.95,
      photoPath: '/path/to/photo1.jpg',
      timestamp: DateTime(2024, 1, 1, 10, 0),
    );

    final word1Again = RecognizedWord(
      enLabel: 'dog',
      esLabel: 'perro',
      confidence: 0.92,
      photoPath: '/path/to/photo3.jpg',
      timestamp: DateTime(2024, 1, 1, 10, 2),
    );

    final word1Later = RecognizedWord(
      enLabel: 'dog',
      esLabel: 'perro',
      confidence: 0.90,
      photoPath: '/path/to/photo4.jpg',
      timestamp: DateTime(2024, 1, 1, 10, 10),
    );

    final word2 = RecognizedWord(
      enLabel: 'cat',
      esLabel: 'gato',
      confidence: 0.88,
      photoPath: '/path/to/photo2.jpg',
      timestamp: DateTime(2024, 1, 1, 10, 5),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = HistoryRepositoryImpl(prefs);
    });

    test('log stores a new entry', () async {
      await repository.log(word1);
      final entries = await repository.loadAll();
      expect(entries.length, equals(1));
      expect(entries.first.enLabel, equals('dog'));
    });

    test('5-minute dedup: same word within 5 min updates timestamp, does not add new entry', () async {
      await repository.log(word1);
      await repository.log(word1Again);
      final entries = await repository.loadAll();
      expect(entries.length, equals(1));
      expect(entries.first.timestamp, equals(word1Again.timestamp));
    });

    test('after 5 minutes, same word is added as a new entry', () async {
      await repository.log(word1);
      await repository.log(word1Later);
      final entries = await repository.loadAll();
      expect(entries.length, equals(2));
    });

    test('log prepends new entries (reverse chronological)', () async {
      await repository.log(word1);
      await repository.log(word2);
      final entries = await repository.loadAll();
      expect(entries.length, equals(2));
      expect(entries.first.enLabel, equals('cat'));
      expect(entries.last.enLabel, equals('dog'));
    });

    test('search finds matches by English label', () async {
      await repository.log(word1);
      await repository.log(word2);
      final results = await repository.search('do');
      expect(results.length, equals(1));
      expect(results.first.enLabel, equals('dog'));
    });

    test('search finds matches by Spanish label', () async {
      await repository.log(word1);
      await repository.log(word2);
      final results = await repository.search('ga');
      expect(results.length, equals(1));
      expect(results.first.esLabel, equals('gato'));
    });

    test('search is case-insensitive', () async {
      await repository.log(word1);
      final results = await repository.search('DOG');
      expect(results.length, equals(1));
    });

    test('search returns empty list when no match', () async {
      await repository.log(word1);
      final results = await repository.search('xyz');
      expect(results, isEmpty);
    });
  });
}
