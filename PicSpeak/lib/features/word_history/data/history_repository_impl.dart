import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/current_user.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../domain/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  static const _maxEntries = 200;
  final SharedPreferences _prefs;

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  HistoryRepositoryImpl(this._prefs);

  @override
  Future<void> log(RecognizedWord word) async {
    final entries = await loadAll();

    final existingIndex = entries.indexWhere(
      (e) => e.enLabel.toLowerCase() == word.enLabel.toLowerCase(),
    );

    if (existingIndex != -1) {
      final existing = entries[existingIndex];
      final diff = word.timestamp.difference(existing.timestamp);
      if (diff.inMinutes.abs() < 5) {
        entries[existingIndex] = existing.copyWith(timestamp: word.timestamp);
        await _persist(entries);
        return;
      }
    }

    entries.insert(0, word);

    while (entries.length > _maxEntries) {
      entries.removeLast();
    }

    await _persist(entries);
  }

  @override
  Future<List<RecognizedWord>> loadAll() async {
    final key = _key('word_history');
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return [];
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => RecognizedWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RecognizedWord>> search(String query) async {
    final entries = await loadAll();
    final lowerQuery = query.toLowerCase();
    return entries.where((e) {
      return e.enLabel.toLowerCase().contains(lowerQuery) ||
          e.esLabel.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _persist(List<RecognizedWord> entries) async {
    final jsonString = jsonEncode(entries.map((w) => w.toJson()).toList());
    await _prefs.setString(_key('word_history'), jsonString);
  }
}
