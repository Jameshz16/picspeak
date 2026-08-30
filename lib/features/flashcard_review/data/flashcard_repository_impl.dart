import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/current_user.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../domain/flashcard_repository.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final SharedPreferences _prefs;

  FlashcardRepositoryImpl(this._prefs);

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  /// Reads a user-scoped key with a one-time migration from the legacy
  /// unscoped key. Once migrated the legacy key is removed so a future
  /// different user on the same device never sees the previous user's data.
  String? _getWithLegacy(String base) {
    final scoped = _prefs.getString(_key(base));
    if (scoped != null) return scoped;
    if (currentUserId.isEmpty) return null;
    final legacy = _prefs.getString(base);
    if (legacy != null) {
      _prefs.setString(_key(base), legacy);
      _prefs.remove(base);
      return legacy;
    }
    return null;
  }

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
    final jsonString = _getWithLegacy('flashcards');
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

  @override
  Future<List<RecognizedWord>> getDueCards() async {
    final cards = await loadAll();
    final now = DateTime.now();
    return cards.where((card) {
      if (card.nextReview == null) return true;
      return card.nextReview!.isBefore(now);
    }).toList();
  }

  @override
  Future<void> updateSrs({
    required String enLabel,
    required int interval,
    required double easeFactor,
    required DateTime nextReview,
  }) async {
    final cards = await loadAll();
    final index = cards.indexWhere((c) => c.enLabel == enLabel);
    if (index == -1) return;

    final card = cards[index];
    cards[index] = card.copyWith(
      interval: interval,
      easeFactor: easeFactor,
      nextReview: nextReview,
      reviewCount: card.reviewCount + 1,
    );
    await _persist(cards);
  }

  @override
  Future<int> getDueCount() async {
    final due = await getDueCards();
    return due.length;
  }

  Future<void> _persist(List<RecognizedWord> cards) async {
    final jsonString = jsonEncode(cards.map((w) => w.toJson()).toList());
    await _prefs.setString(_key('flashcards'), jsonString);
  }
}
