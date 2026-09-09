import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/data/phrase_repository.dart';
import '../domain/ai_translation_repository.dart';
import 'ai_translation_repository_impl.dart';

/// Provides the [AiTranslationRepository] singleton.
///
/// Loads DEEPSEEK_API_KEY from .env. Throws if the key is missing.
final aiTranslationRepositoryProvider = FutureProvider<AiTranslationRepository>(
  (ref) async {
    await dotenv.load(fileName: '.env');
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('DEEPSEEK_API_KEY not found in .env');
    }
    return AiTranslationRepositoryImpl(
      FirebaseFirestore.instance,
      http.Client(),
      apiKey,
    );
  },
);

/// Holds AI-generated phrases for the current scan, to pass to ResultScreen.
final aiPhrasesProvider = StateProvider<List<PhrasePair>?>((ref) => null);
