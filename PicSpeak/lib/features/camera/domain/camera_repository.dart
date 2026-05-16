import 'package:camera/camera.dart';

abstract class CameraRepository {
  CameraController? get controller;
  Future<void> initialize();
  Future<String> takePicture();
  void dispose();
  bool get isReady;
}
