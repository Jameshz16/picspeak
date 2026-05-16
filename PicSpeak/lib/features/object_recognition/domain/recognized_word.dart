import 'labeled_object.dart';

class RecognizedWord {
  final String enLabel;
  final String esLabel;
  final double confidence;
  final String photoPath;
  final DateTime timestamp;

  const RecognizedWord({
    required this.enLabel,
    required this.esLabel,
    required this.confidence,
    required this.photoPath,
    required this.timestamp,
  });

  RecognizedWord copyWith({
    String? enLabel,
    String? esLabel,
    double? confidence,
    String? photoPath,
    DateTime? timestamp,
  }) {
    return RecognizedWord(
      enLabel: enLabel ?? this.enLabel,
      esLabel: esLabel ?? this.esLabel,
      confidence: confidence ?? this.confidence,
      photoPath: photoPath ?? this.photoPath,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enLabel': enLabel,
      'esLabel': esLabel,
      'confidence': confidence,
      'photoPath': photoPath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RecognizedWord.fromJson(Map<String, dynamic> json) {
    return RecognizedWord(
      enLabel: json['enLabel'] as String,
      esLabel: json['esLabel'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      photoPath: json['photoPath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  factory RecognizedWord.fromMlKit(
    LabeledObject label,
    String? esTranslation,
    String photoPath,
  ) {
    return RecognizedWord(
      enLabel: label.label,
      esLabel: esTranslation ?? 'Traducción no disponible',
      confidence: label.confidence,
      photoPath: photoPath,
      timestamp: DateTime.now(),
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
