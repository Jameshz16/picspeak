import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/phrase_repository.dart';

/// Result from AI-powered translation (DeepSeek Vision).
class AiTranslationResult {
  final String enLabel;
  final String esLabel;
  final List<PhrasePair> phrases;
  final double aiConfidence;
  final String modelVersion;
  final DateTime cachedAt;

  const AiTranslationResult({
    required this.enLabel,
    required this.esLabel,
    required this.phrases,
    required this.aiConfidence,
    required this.modelVersion,
    required this.cachedAt,
  });

  factory AiTranslationResult.fromFirestore(Map<String, dynamic> data) {
    return AiTranslationResult(
      enLabel: data['enLabel'] as String,
      esLabel: data['esLabel'] as String,
      phrases: (data['phrases'] as List)
          .map((p) => PhrasePair(en: p['en'] as String, es: p['es'] as String))
          .toList(),
      aiConfidence: (data['aiConfidence'] as num).toDouble(),
      modelVersion: data['modelVersion'] as String,
      cachedAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enLabel': enLabel,
      'esLabel': esLabel,
      'phrases': phrases.map((p) => {'en': p.en, 'es': p.es}).toList(),
      'aiConfidence': aiConfidence,
      'modelVersion': modelVersion,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Repository interface for AI-powered translation fallback.
///
/// Used when a label detected by ML Kit is not in the curated word list.
/// Falls back to DeepSeek Vision API with Firestore caching.
abstract class AiTranslationRepository {
  /// Translates an image+label using DeepSeek Vision.
  ///
  /// Returns [AiTranslationResult] on success, `null` if the API fails
  /// or returns unparseable data.
  ///
  /// Throws [AiTranslationOfflineException] if offline and not cached.
  Future<AiTranslationResult?> translate(String imagePath, String enLabel);
}

/// Thrown when the device is offline and the translation is not cached.
class AiTranslationOfflineException implements Exception {
  final String message;
  const AiTranslationOfflineException([
    this.message = 'Necesitás internet para esta palabra',
  ]);
  @override
  String toString() => message;
}
