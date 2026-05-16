import '../../object_recognition/domain/recognized_word.dart';

abstract class FlashcardRepository {
  Future<void> save(RecognizedWord word);
  Future<List<RecognizedWord>> loadAll();
  Future<bool> exists(String enLabel);
  Future<void> remove(String enLabel);
}
