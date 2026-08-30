import 'dart:ui';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../domain/labeled_object.dart';
import '../domain/mlkit_repository.dart';

class MlKitRepositoryImpl implements MlKitRepository {
  final ImageLabeler _labeler;
  final ObjectDetector _detector;

  MlKitRepositoryImpl({ImageLabeler? labeler, ObjectDetector? detector})
      : _labeler = labeler ??
            ImageLabeler(
              options: ImageLabelerOptions(confidenceThreshold: 0.7),
            ),
        _detector = detector ??
            ObjectDetector(
              options: ObjectDetectorOptions(
                mode: DetectionMode.single,
                classifyObjects: false,
                multipleObjects: false,
              ),
            );

  @override
  Future<List<LabeledObject>> labelImage(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    
    final labelsFuture = _labeler.processImage(input);
    final objectsFuture = _detector.processImage(input);

    final results = await Future.wait([labelsFuture, objectsFuture]);
    final labels = results[0] as List<ImageLabel>;
    final objects = results[1] as List<DetectedObject>;

    Rect? primaryBoundingBox;
    if (objects.isNotEmpty) {
      primaryBoundingBox = objects.first.boundingBox;
    }

    final filtered = labels.where((l) => l.confidence >= 0.7).toList();
    filtered.sort((a, b) => b.confidence.compareTo(a.confidence));

    final resultsList = <LabeledObject>[];
    for (int i = 0; i < filtered.length; i++) {
      resultsList.add(
        LabeledObject(
          label: filtered[i].label,
          confidence: filtered[i].confidence,
          // Only attach bounding box to the primary (highest confidence) label
          boundingBox: i == 0 ? primaryBoundingBox : null,
        ),
      );
    }
    return resultsList;
  }

  @override
  void dispose() {
    _labeler.close();
    _detector.close();
  }
}

