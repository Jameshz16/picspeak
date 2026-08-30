import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/label_map_repository.dart';
import '../../../core/utils/current_user.dart';

/// Daily challenge word that gives the user direction.
///
/// Each day, picks a random word from the vocabulary that the user
/// should try to find and scan. Stored per-user in SharedPreferences.
class WordOfDayRepository {
  final SharedPreferences _prefs;
  final LabelMapRepository _labelMap;

  WordOfDayRepository(this._prefs, this._labelMap);

  String _key(String base) =>
      currentUserId.isEmpty ? base : '${currentUserId}_$base';

  String get _today {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Get today's word. Picks a new one if the date changed.
  WordOfDay getToday() {
    final storedDate = _prefs.getString(_key('word_of_day_date'));
    final storedWord = _prefs.getString(_key('word_of_day_en'));
    final storedEs = _prefs.getString(_key('word_of_day_es'));
    final storedCategory = _prefs.getString(_key('word_of_day_cat'));

    if (storedDate == _today &&
        storedWord != null &&
        storedEs != null &&
        storedCategory != null) {
      return WordOfDay(
        enWord: storedWord,
        esWord: storedEs,
        category: storedCategory,
        date: _today,
      );
    }

    // Pick a new random word
    return _pickNew();
  }

  /// Mark today's word as found.
  Future<void> markFound() async {
    await _prefs.setBool(_key('word_of_day_found_$_today'), true);
  }

  /// Check if today's word was already found.
  bool isFound() {
    return _prefs.getBool(_key('word_of_day_found_$_today')) ?? false;
  }

  WordOfDay _pickNew() {
    final random = Random();
    final categories = _labelMap.getCategories();
    
    // Pick a random category
    final category = categories[random.nextInt(categories.length)];
    
    // Pick a random word from that category
    final words = _labelMap.getWordsInCategory(category.id);
    if (words.isEmpty) {
      // Fallback: pick from any category
      for (final cat in categories) {
        final w = _labelMap.getWordsInCategory(cat.id);
        if (w.isNotEmpty) {
          final entry = w[random.nextInt(w.length)];
          return _saveAndReturn(entry.key, entry.value, cat.id);
        }
      }
      // Ultimate fallback
      return _saveAndReturn('Chair', 'Silla', 'home');
    }
    
    final entry = words[random.nextInt(words.length)];
    return _saveAndReturn(entry.key, entry.value, category.id);
  }

  WordOfDay _saveAndReturn(String en, String es, String cat) {
    _prefs.setString(_key('word_of_day_en'), en);
    _prefs.setString(_key('word_of_day_es'), es);
    _prefs.setString(_key('word_of_day_cat'), cat);
    _prefs.setString(_key('word_of_day_date'), _today);
    // Clear found flag for new word
    _prefs.remove(_key('word_of_day_found_$_today'));

    return WordOfDay(
      enWord: en,
      esWord: es,
      category: cat,
      date: _today,
    );
  }
}

/// A daily challenge word.
class WordOfDay {
  final String enWord;
  final String esWord;
  final String category;
  final String date;

  const WordOfDay({
    required this.enWord,
    required this.esWord,
    required this.category,
    required this.date,
  });

  /// Get a hint for the word (first letter + underscores).
  String get hint {
    if (enWord.length <= 2) return enWord;
    return '${enWord[0]}${'_' * (enWord.length - 1)}';
  }

  /// Get category display name.
  String get categoryName {
    const names = {
      'animals': 'Animales',
      'food': 'Comida',
      'clothing': 'Ropa',
      'home': 'Hogar',
      'vehicles': 'Vehículos',
      'nature': 'Naturaleza',
      'technology': 'Tecnología',
      'body': 'Cuerpo',
      'music': 'Música',
      'sports': 'Deportes',
      'buildings': 'Edificios',
      'tools': 'Herramientas',
      'toys_kids': 'Juguetes',
      'places': 'Lugares',
      'other': 'Otros',
    };
    return names[category] ?? category;
  }

  /// Get category icon name.
  String get categoryIcon {
    const icons = {
      'animals': 'pets',
      'food': 'restaurant',
      'clothing': 'checkroom',
      'home': 'home',
      'vehicles': 'directions_car',
      'nature': 'nature',
      'technology': 'devices',
      'body': 'accessibility_new',
      'music': 'music_note',
      'sports': 'sports_soccer',
      'buildings': 'location_city',
      'tools': 'build',
      'toys_kids': 'toys',
      'places': 'explore',
      'other': 'more_horiz',
    };
    return icons[category] ?? 'category';
  }
}

/// Provider for the Word of the Day repository.
final wordOfDayRepositoryProvider = FutureProvider<WordOfDayRepository>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final labelMap = await ref.watch(labelMapProvider.future);
  return WordOfDayRepository(prefs, labelMap);
});

/// Provider for today's word.
final wordOfDayProvider = FutureProvider<WordOfDay>((ref) async {
  final repo = await ref.watch(wordOfDayRepositoryProvider.future);
  return repo.getToday();
});

/// Provider for whether today's word was found.
final wordOfDayFoundProvider = FutureProvider<bool>((ref) async {
  final repo = await ref.watch(wordOfDayRepositoryProvider.future);
  return repo.isFound();
});
