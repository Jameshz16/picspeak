import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class PermissionService {
  Stream<PermissionStatus> get cameraPermissionStatus;
  Future<void> requestCameraPermission();
  Future<bool> get isCameraPermissionGranted;
}

class PermissionServiceImpl implements PermissionService {
  final _statusController = StreamController<PermissionStatus>.broadcast();

  @override
  Stream<PermissionStatus> get cameraPermissionStatus async* {
    yield await Permission.camera.status;
    yield* _statusController.stream;
  }

  @override
  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    _statusController.add(status);
  }

  @override
  Future<bool> get isCameraPermissionGranted async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  void dispose() {
    _statusController.close();
  }
}

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionServiceImpl(),
);

final cameraPermissionProvider = StreamProvider<PermissionStatus>((ref) {
  final service = ref.watch(permissionServiceProvider);
  return service.cameraPermissionStatus;
});
