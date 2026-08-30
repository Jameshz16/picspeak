import 'labeled_object.dart';

abstract class MlKitRepository {
  Future<List<LabeledObject>> labelImage(String imagePath);
  void dispose();
}
