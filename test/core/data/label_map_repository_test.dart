import 'package:flutter_test/flutter_test.dart';
import 'package:picspeak/core/data/label_map_repository.dart';
import 'package:picspeak/core/data/word_category.dart';

class _TestLabelMapRepository implements LabelMapRepository {
  final Map<String, String> _map;

  _TestLabelMapRepository(this._map);

  @override
  String? translate(String enLabel) => _map[enLabel];

  @override
  List<WordCategory> getCategories() => [];

  @override
  List<MapEntry<String, String>> getWordsInCategory(String categoryId) => [];

  @override
  String getCategoryForWord(String enLabel) => 'other';

  @override
  int get wordCount => _map.length;

  @override
  Future<void> loadMap() async {}
}

void main() {
  group('LabelMapRepository.translate', () {
    late LabelMapRepository repository;

    setUp(() {
      repository = _TestLabelMapRepository({
        'dog': 'perro',
        'cat': 'gato',
        'house': 'casa',
      });
    });

    test('returns Spanish translation for known label', () {
      expect(repository.translate('dog'), equals('perro'));
      expect(repository.translate('cat'), equals('gato'));
      expect(repository.translate('house'), equals('casa'));
    });

    test('returns null for unknown label', () {
      expect(repository.translate('unknown_label'), isNull);
      expect(repository.translate('xyz'), isNull);
    });

    test('returns null for null-equivalent or empty inputs', () {
      expect(repository.translate(''), isNull);
      expect(repository.translate('nonexistent'), isNull);
    });
  });
}
