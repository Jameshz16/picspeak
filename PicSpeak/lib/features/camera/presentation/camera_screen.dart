import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/data/label_map_repository.dart';
import '../../../core/services/permission_service.dart';
import '../../object_recognition/data/object_recognition_providers.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../data/camera_providers.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(cameraNotifierProvider.notifier);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      notifier.pause();
    } else if (state == AppLifecycleState.resumed) {
      notifier.resume();
    }
  }

  Future<void> _onCapture() async {
    setState(() => _isProcessing = true);
    try {
      final path = await ref.read(cameraNotifierProvider.notifier).takePicture();
      final labels =
          await ref.read(mlKitRepositoryProvider).labelImage(path);

      if (labels.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No object recognized. Try again.'),
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      final labelMapRepo = await ref.read(labelMapProvider.future);
      final topLabel = labels.first;
      final esTranslation = labelMapRepo.translate(topLabel.label);
      final word = RecognizedWord.fromMlKit(
        topLabel,
        esTranslation,
        path,
      );

      if (mounted) {
        context.push('/result', extra: {
          'word': word,
          'allLabels': labels,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionAsync = ref.watch(cameraPermissionProvider);
    final cameraState = ref.watch(cameraNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: permissionAsync.when(
        data: (status) => _buildForPermission(status, cameraState),
        loading: () => const _LoadingView(message: 'Checking permissions...'),
        error: (err, _) => _ErrorView(message: err.toString()),
      ),
    );
  }

  Widget _buildForPermission(PermissionStatus status, AsyncValue<void> cameraState) {
    if (status.isGranted || status.isLimited) {
      return cameraState.when(
        data: (_) => _buildCameraPreview(),
        loading: () => const _LoadingView(message: 'Starting camera...'),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.read(cameraNotifierProvider.notifier).resume(),
        ),
      );
    }

    if (status.isPermanentlyDenied) {
      return _PermissionDeniedView(
        permanentlyDenied: true,
        onOpenSettings: () => openAppSettings(),
      );
    }

    if (status.isRestricted) {
      return const _PermissionDeniedView(
        message:
            'Camera access is restricted on this device. A parent or guardian may need to adjust the restriction.',
      );
    }

    return _PermissionDeniedView(
      onRequestPermission: () async {
        await ref.read(permissionServiceProvider).requestCameraPermission();
      },
    );
  }

  Widget _buildCameraPreview() {
    final controller = ref.read(cameraRepositoryProvider).controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _LoadingView(message: 'Starting camera...');
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: FloatingActionButton.large(
              onPressed: _isProcessing ? null : _onCapture,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.camera_alt, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final String? message;
  final bool permanentlyDenied;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onOpenSettings;

  const _PermissionDeniedView({
    this.message,
    this.permanentlyDenied = false,
    this.onRequestPermission,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white54, size: 64),
            const SizedBox(height: 24),
            Text(
              message ??
                  (permanentlyDenied
                      ? 'Camera permission is permanently denied. Please enable it in settings to use this feature.'
                      : 'PicSpeak needs camera access to identify objects around you. Please grant permission to continue.'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRequestPermission != null)
              ElevatedButton(
                onPressed: onRequestPermission,
                child: const Text('Grant Permission'),
              ),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
