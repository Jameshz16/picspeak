import 'dart:ui';

class LabeledObject {
  final String label;
  final double confidence;
  final Rect? boundingBox;

  const LabeledObject({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });
}

