import 'package:camera/camera.dart';

import '../domain/camera_repository.dart';

class CameraRepositoryImpl implements CameraRepository {
  CameraController? _controller;

  @override
  CameraController? get controller => _controller;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device.');
      }
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
    } on CameraException catch (e) {
      throw Exception('Camera initialization failed: ${e.description}');
    } catch (e) {
      throw Exception('Camera initialization failed: $e');
    }
  }

  @override
  Future<String> takePicture() async {
    if (!isReady) {
      throw Exception('Camera is not initialized.');
    }
    try {
      final file = await _controller!.takePicture();
      return file.path;
    } on CameraException catch (e) {
      throw Exception('Failed to take picture: ${e.description}');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
