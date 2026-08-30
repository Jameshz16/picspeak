import 'dart:ui';
import 'labeled_object.dart';

class RecognizedWord {
  /// Sentinel value used when no Spanish translation is available.
  static const noTranslationSentinel = 'Sin traducción';

  final String enLabel;
  final String esLabel;
  final double confidence;
  final String photoPath;
  final DateTime timestamp;
  final Rect? boundingBox;

  // SRS fields
  final DateTime? nextReview;
  final double easeFactor;
  final int interval;
  final int reviewCount;

  const RecognizedWord({
    required this.enLabel,
    required this.esLabel,
    required this.confidence,
    required this.photoPath,
    required this.timestamp,
    this.boundingBox,
    this.nextReview,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.reviewCount = 0,
  });

  RecognizedWord copyWith({
    String? enLabel,
    String? esLabel,
    double? confidence,
    String? photoPath,
    DateTime? timestamp,
    Rect? boundingBox,
    DateTime? nextReview,
    double? easeFactor,
    int? interval,
    int? reviewCount,
  }) {
    return RecognizedWord(
      enLabel: enLabel ?? this.enLabel,
      esLabel: esLabel ?? this.esLabel,
      confidence: confidence ?? this.confidence,
      photoPath: photoPath ?? this.photoPath,
      timestamp: timestamp ?? this.timestamp,
      boundingBox: boundingBox ?? this.boundingBox,
      nextReview: nextReview ?? this.nextReview,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enLabel': enLabel,
      'esLabel': esLabel,
      'confidence': confidence,
      'photoPath': photoPath,
      'timestamp': timestamp.toIso8601String(),
      'boundingBox': boundingBox != null
          ? {
              'left': boundingBox!.left,
              'top': boundingBox!.top,
              'width': boundingBox!.width,
              'height': boundingBox!.height,
            }
          : null,
      'nextReview': nextReview?.toIso8601String(),
      'easeFactor': easeFactor,
      'interval': interval,
      'reviewCount': reviewCount,
    };
  }

  factory RecognizedWord.fromJson(Map<String, dynamic> json) {
    return RecognizedWord(
      enLabel: json['enLabel'] as String,
      esLabel: json['esLabel'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      photoPath: json['photoPath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      boundingBox: json['boundingBox'] != null
          ? Rect.fromLTWH(
              (json['boundingBox']['left'] as num).toDouble(),
              (json['boundingBox']['top'] as num).toDouble(),
              (json['boundingBox']['width'] as num).toDouble(),
              (json['boundingBox']['height'] as num).toDouble(),
            )
          : null,
      nextReview: json['nextReview'] != null
          ? DateTime.parse(json['nextReview'] as String)
          : null,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: (json['interval'] as num?)?.toInt() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory RecognizedWord.fromMlKit(
    LabeledObject label,
    String? esTranslation,
    String photoPath,
  ) {
    return RecognizedWord(
      enLabel: label.label,
      esLabel: esTranslation ?? noTranslationSentinel,
      confidence: label.confidence,
      photoPath: photoPath,
      timestamp: DateTime.now(),
      boundingBox: label.boundingBox,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognizedWord &&
          runtimeType == other.runtimeType &&
          enLabel == other.enLabel &&
          photoPath == other.photoPath;

  @override
  int get hashCode => enLabel.hashCode ^ photoPath.hashCode;
}
