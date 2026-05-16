import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/permission_service.dart';
import '../domain/camera_repository.dart';
import 'camera_repository_impl.dart';

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepositoryImpl();
});

class CameraNotifier extends StateNotifier<AsyncValue<void>> {
  final CameraRepository _repository;
  final PermissionService _permissionService;

  CameraNotifier(this._repository, this._permissionService)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final granted = await _permissionService.isCameraPermissionGranted;
      if (!granted) {
        state = AsyncValue.error(
          'Camera permission is required to use this feature.',
          StackTrace.current,
        );
        return;
      }
      await _repository.initialize();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resume() async {
    if (!_repository.isReady) {
      state = const AsyncValue.loading();
      await _init();
    }
  }

  void pause() {
    _repository.dispose();
    state = const AsyncValue.loading();
  }

  Future<String> takePicture() async {
    return _repository.takePicture();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}

final cameraNotifierProvider =
    StateNotifierProvider<CameraNotifier, AsyncValue<void>>((ref) {
  final cameraRepo = ref.watch(cameraRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  return CameraNotifier(cameraRepo, permissionService);
});
