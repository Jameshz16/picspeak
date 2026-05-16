import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../domain/labeled_object.dart';
import '../domain/mlkit_repository.dart';

class MlKitRepositoryImpl implements MlKitRepository {
  final ImageLabeler _labeler;

  MlKitRepositoryImpl({ImageLabeler? labeler})
      : _labeler = labeler ??
            ImageLabeler(
              options: ImageLabelerOptions(confidenceThreshold: 0.7),
            );

  @override
  Future<List<LabeledObject>> labelImage(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final labels = await _labeler.processImage(input);

    final results = labels
        .where((l) => l.confidence >= 0.7)
        .map(
          (l) => LabeledObject(
            label: l.label,
            confidence: l.confidence,
          ),
        )
        .toList();

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  @override
  void dispose() {
    _labeler.close();
  }
}
