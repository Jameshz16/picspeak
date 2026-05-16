import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picspeak/features/camera/presentation/camera_screen.dart';
import 'package:picspeak/core/services/permission_service.dart';
import 'package:picspeak/features/camera/data/camera_providers.dart';
import 'package:picspeak/features/camera/domain/camera_repository.dart';
import 'package:camera/camera.dart';

class _MockPermissionService implements PermissionService {
  final PermissionStatus _status;

  _MockPermissionService(this._status);

  @override
  Stream<PermissionStatus> get cameraPermissionStatus async* {
    yield _status;
  }

  @override
  Future<void> requestCameraPermission() async {}

  @override
  Future<bool> get isCameraPermissionGranted async => _status.isGranted;
}

class _MockCameraRepository implements CameraRepository {
  @override
  CameraController? get controller => null;

  @override
  bool get isReady => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> takePicture() async => '';

  @override
  void dispose() {}
}

void main() {
  group('CameraScreen', () {
    testWidgets('shows loading state when permission is granted (camera not available in tests)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(
              _MockPermissionService(PermissionStatus.granted),
            ),
            cameraRepositoryProvider.overrideWithValue(_MockCameraRepository()),
            cameraNotifierProvider.overrideWith((ref) {
              return CameraNotifier(
                ref.read(cameraRepositoryProvider),
                ref.read(permissionServiceProvider),
              );
            }),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pump();

      // In test environment, camera controller cannot initialize, so we see loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Starting camera...'), findsOneWidget);
    });

    testWidgets('shows explanation + settings link when permission is permanently denied',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(
              _MockPermissionService(PermissionStatus.permanentlyDenied),
            ),
            cameraRepositoryProvider.overrideWithValue(_MockCameraRepository()),
            cameraNotifierProvider.overrideWith((ref) {
              return CameraNotifier(
                ref.read(cameraRepositoryProvider),
                ref.read(permissionServiceProvider),
              );
            }),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Open Settings'), findsOneWidget);
      expect(
        find.textContaining('permanently denied'),
        findsOneWidget,
      );
    });

    testWidgets('shows grant permission button when permission is denied',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(
              _MockPermissionService(PermissionStatus.denied),
            ),
            cameraRepositoryProvider.overrideWithValue(_MockCameraRepository()),
            cameraNotifierProvider.overrideWith((ref) {
              return CameraNotifier(
                ref.read(cameraRepositoryProvider),
                ref.read(permissionServiceProvider),
              );
            }),
          ],
          child: const MaterialApp(
            home: CameraScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Grant Permission'), findsOneWidget);
    });
  });
}
