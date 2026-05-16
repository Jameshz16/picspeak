import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../object_recognition/domain/recognized_word.dart';
import '../domain/flashcard_repository.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  static const _key = 'flashcards';
  final SharedPreferences _prefs;

  FlashcardRepositoryImpl(this._prefs);

  @override
  Future<void> save(RecognizedWord word) async {
    final cards = await loadAll();
    if (await exists(word.enLabel)) {
      return;
    }
    cards.add(word);
    await _persist(cards);
  }

  @override
  Future<List<RecognizedWord>> loadAll() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return [];
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => RecognizedWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> exists(String enLabel) async {
    final cards = await loadAll();
    return cards.any((c) => c.enLabel == enLabel);
  }

  @override
  Future<void> remove(String enLabel) async {
    final cards = await loadAll();
    cards.removeWhere((c) => c.enLabel == enLabel);
    await _persist(cards);
  }

  Future<void> _persist(List<RecognizedWord> cards) async {
    final jsonString = jsonEncode(cards.map((w) => w.toJson()).toList());
    await _prefs.setString(_key, jsonString);
  }
}
