import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../core/data/phrase_repository.dart';
import '../domain/ai_translation_repository.dart';

/// Implementation of [AiTranslationRepository] using DeepSeek Vision API
/// with Firestore caching.
class AiTranslationRepositoryImpl implements AiTranslationRepository {
  final FirebaseFirestore _firestore;
  final http.Client _httpClient;
  final String _apiKey;

  static const _collection = 'ai_translations';
  static const _model = 'deepseek-v4-flash-vision-exp';
  static const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  AiTranslationRepositoryImpl(this._firestore, this._httpClient, this._apiKey);

  @override
  Future<AiTranslationResult?> translate(
    String imagePath,
    String enLabel,
  ) async {
    final cacheKey = enLabel.toLowerCase().trim();

    // 1. Check Firestore cache
    final cached = await _getFromCache(cacheKey);
    if (cached != null) return cached;

    // 2. Call DeepSeek Vision (offline detection via exceptions)
    try {
      final result = await _callDeepSeekVision(imagePath, enLabel);
      if (result == null) return null;

      // 3. Cache result (non-fatal if it fails)
      await _saveToCache(cacheKey, result);

      return result;
    } on SocketException {
      throw const AiTranslationOfflineException();
    } on TimeoutException {
      throw const AiTranslationOfflineException();
    } on http.ClientException {
      throw const AiTranslationOfflineException();
    } on FileSystemException {
      throw const AiTranslationOfflineException();
    }
  }

  // ---------------------------------------------------------------------------
  // Firestore cache
  // ---------------------------------------------------------------------------

  Future<AiTranslationResult?> _getFromCache(String cacheKey) async {
    try {
      final doc = await _firestore.collection(_collection).doc(cacheKey).get();
      if (doc.exists && doc.data() != null) {
        return AiTranslationResult.fromFirestore(doc.data()!);
      }
    } catch (_) {
      // Cache read failure is non-fatal, continue to API
    }
    return null;
  }

  Future<void> _saveToCache(String cacheKey, AiTranslationResult result) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(cacheKey)
          .set(result.toFirestore());
    } catch (_) {
      // Cache write failure is non-fatal
    }
  }

  // ---------------------------------------------------------------------------
  // DeepSeek Vision API
  // ---------------------------------------------------------------------------

  Future<AiTranslationResult?> _callDeepSeekVision(
    String imagePath,
    String enLabel, {
    int retriesLeft = 1,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final response = await _httpClient
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                  },
                  {
                    'type': 'text',
                    'text':
                        '''You are a bilingual English-Spanish translator for a language learning app.

The object in this image was detected as: "$enLabel"

Respond with ONLY valid JSON (no markdown, no explanation):
{
  "esLabel": "Spanish translation of $enLabel",
  "phrases": [
    {"en": "Simple English sentence using the word", "es": "Spanish translation"},
    {"en": "Another simple sentence", "es": "Spanish translation"}
  ],
  "confidence": 0.9
}

Rules:
- Use A1-A2 level vocabulary
- Keep sentences short (max 10 words)
- confidence: 0.0-1.0 based on how clear the object is
- If the object is unclear, still provide your best guess''',
                  },
                ],
              },
            ],
            'max_tokens': 500,
            'temperature': 0.3,
          }),
        )
        .timeout(const Duration(seconds: 15));

    // Retry once for transient errors
    if ((response.statusCode == 429 || response.statusCode >= 500) &&
        retriesLeft > 0) {
      await Future.delayed(const Duration(seconds: 1));
      return _callDeepSeekVision(imagePath, enLabel, retriesLeft: 0);
    }

    if (response.statusCode != 200) return null;

    return _parseResponse(response.body, enLabel);
  }

  // ---------------------------------------------------------------------------
  // Response parsing
  // ---------------------------------------------------------------------------

  AiTranslationResult? _parseResponse(String body, String enLabel) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      final content = choices[0]['message']['content'] as String?;
      if (content == null) return null;

      // Strip markdown fences if the model wraps JSON in ```json ... ```
      final cleanContent = content
          .replaceAll(RegExp(r'^```json\s*'), '')
          .replaceAll(RegExp(r'^```\s*'), '')
          .replaceAll(RegExp(r'\s*```$'), '')
          .trim();

      final parsed = jsonDecode(cleanContent) as Map<String, dynamic>;
      final phrases = (parsed['phrases'] as List)
          .map((p) => PhrasePair(en: p['en'] as String, es: p['es'] as String))
          .toList();

      return AiTranslationResult(
        enLabel: enLabel,
        esLabel: parsed['esLabel'] as String,
        phrases: phrases,
        aiConfidence: (parsed['confidence'] as num).toDouble(),
        modelVersion: _model,
        cachedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
