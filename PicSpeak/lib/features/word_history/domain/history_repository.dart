import '../../object_recognition/domain/recognized_word.dart';

abstract class HistoryRepository {
  Future<void> log(RecognizedWord word);
  Future<List<RecognizedWord>> loadAll();
  Future<List<RecognizedWord>> search(String query);
}
