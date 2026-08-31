import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A pair of sentences: English source and Spanish translation.
class PhrasePair {
  final String en;
  final String es;

  const PhrasePair({required this.en, required this.es});
}

/// Repository that provides example phrases for vocabulary words.
abstract class PhraseRepository {
  /// Returns phrase pairs for the given English label, or `null` if none exist.
  List<PhrasePair>? getPhrases(String enLabel);
}

class PhraseRepositoryImpl implements PhraseRepository {
  Map<String, List<PhrasePair>> _phrases = {};

  Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/phrases_en.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    final result = <String, List<PhrasePair>>{};
    for (final entry in decoded.entries) {
      final word = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final enList = (data['en'] as List).cast<String>();
      final esList = (data['es'] as List).cast<String>();

      final pairs = <PhrasePair>[];
      for (var i = 0; i < enList.length && i < esList.length; i++) {
        pairs.add(PhrasePair(en: enList[i], es: esList[i]));
      }
      result[word] = pairs;
    }
    _phrases = result;
  }

  @override
  List<PhrasePair>? getPhrases(String enLabel) {
    return _phrases[enLabel];
  }
}

final phraseRepositoryProvider = FutureProvider<PhraseRepository>((ref) async {
  final repository = PhraseRepositoryImpl();
  await repository.load();
  return repository;
});
