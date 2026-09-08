import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/sb_animations.dart';
import '../../../app/sb_colors.dart';
import '../../../app/sb_radius.dart';
import '../../../core/data/label_map_repository.dart';
import '../../../core/services/permission_service.dart';
import '../../object_recognition/data/object_recognition_providers.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../../premium/data/premium_providers.dart';
import '../../premium/domain/scan_limit_repository.dart';
import '../../premium/presentation/admob_banner_widget.dart';
import '../../premium/presentation/scan_limit_dialog.dart';
import '../data/camera_providers.dart';
import '../data/word_of_day_repository.dart';

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
    // Check scan limit before processing
    final isPremium = ref.read(isPremiumProvider);
    final scanLimitRepo = ref.read(scanLimitRepositoryProvider);
    final hasReached =
        await scanLimitRepo.hasReachedLimit(isPremium: isPremium);

    if (hasReached && mounted) {
      await ScanLimitDialog.show(
        context,
        onUpgrade: () {
          context.push('/paywall');
        },
      );
      return; // Block the scan
    }

    setState(() => _isProcessing = true);
    try {
      final path =
          await ref.read(cameraNotifierProvider.notifier).takePicture();
      final labels =
          await ref.read(mlKitRepositoryProvider).labelImage(path);

      if (labels.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se reconoce ningún objeto. Intenta de nuevo.'),
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
        // Check if this matches the Word of the Day
        final wordOfDayAsync = ref.read(wordOfDayProvider);
        final wordOfDay = wordOfDayAsync.valueOrNull;
        final wordOfDayRepo = ref.read(wordOfDayRepositoryProvider).valueOrNull;
        bool isWordOfDay = false;
        
        if (wordOfDay != null && wordOfDayRepo != null) {
          final scannedLower = word.enLabel.toLowerCase();
          final targetLower = wordOfDay.enWord.toLowerCase();
          isWordOfDay = scannedLower == targetLower && !wordOfDayRepo.isFound();
          
          if (isWordOfDay) {
            await wordOfDayRepo.markFound();
            ref.invalidate(wordOfDayFoundProvider);
          }
        }

        context.push('/result', extra: {
          'word': word,
          'allLabels': labels,
          'isWordOfDay': isWordOfDay,
        });
        // Record the scan (after successful recognition)
        await scanLimitRepo.recordScan();
        // Invalidate remaining scans provider to update UI
        ref.invalidate(remainingScansProvider);
        ref.invalidate(todayScanCountProvider);
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
        loading: () =>
            const _LoadingView(message: 'Verificando permisos...'),
        error: (err, _) => _ErrorView(message: err.toString()),
      ),
    );
  }

  Widget _buildForPermission(
      PermissionStatus status, AsyncValue<void> cameraState) {
    if (status.isGranted || status.isLimited) {
      return cameraState.when(
        data: (_) => _buildCameraPreview(),
        loading: () => const _LoadingView(message: 'Iniciando cámara...'),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.read(cameraNotifierProvider.notifier).resume(),
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
            'El acceso a la cámara está restringido en este dispositivo. Un padre o tutor puede ajustar la restricción.',
      );
    }

    return _PermissionDeniedView(
      onRequestPermission: () async {
        await ref
            .read(permissionServiceProvider)
            .requestCameraPermission();
      },
    );
  }

  Widget _buildCameraPreview() {
    final controller = ref.read(cameraRepositoryProvider).controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _LoadingView(message: 'Iniciando cámara...');
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        // Scan counter badge (top-right)
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: const _ScanCounterBadge(),
        ),
        // Word of the Day (top-left)
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: const _WordOfDayBadge(),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: SbLoadingDots(),
            ),
          ),
        // Banner ad at the bottom (hidden for premium users)
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AdMobBannerWidget(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: SbPulse(
              child: SbPressable(
                child: FloatingActionButton.large(
                  onPressed: _isProcessing ? null : _onCapture,
                  backgroundColor: SbColors.activeBlue,
                  foregroundColor: SbColors.onError,
                  child: const Icon(Icons.camera_alt, size: 40),
                ),
              ),
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
            const SbLoadingDots(),
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
            const Icon(Icons.error_outline,
                color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SbPressable(
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
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
            const Icon(Icons.camera_alt,
                color: Colors.white54, size: 64),
            const SizedBox(height: 24),
            Text(
              message ??
                  (permanentlyDenied
                      ? 'El permiso de cámara fue denegado permanentemente. Habilítalo en configuración para usar esta función.'
                      : 'PicSpeak necesita acceso a la cámara para identificar objetos a tu alrededor. Permite el permiso para continuar.'),
              style: const TextStyle(
                  color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (onRequestPermission != null)
              SbPressable(
                child: ElevatedButton(
                  onPressed: onRequestPermission,
                  child: const Text('Dar permiso'),
                ),
              ),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Abrir Configuración'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge showing remaining daily scans. Tappable to open paywall.
class _ScanCounterBadge extends ConsumerWidget {
  const _ScanCounterBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final remainingAsync = ref.watch(remainingScansProvider);

    if (isPremium) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(SbRadius.secondary),
            ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium,
                size: 16, color: Colors.black87),
            SizedBox(width: 4),
            Text(
              'PRO',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return remainingAsync.when(
      data: (remaining) {
        final isLow = remaining <= 2;
        final color = isLow
            ? Colors.red.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.85);
        final textColor = isLow ? Colors.white : Colors.black87;

        return GestureDetector(
          onTap: () => context.push('/paywall'),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(SbRadius.secondary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(
                  '$remaining/${ScanLimitRepository.dailyFreeLimit}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (isLow) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.lock_open, size: 12, color: textColor),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Badge showing the Word of the Day challenge.
class _WordOfDayBadge extends ConsumerWidget {
  const _WordOfDayBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordOfDayAsync = ref.watch(wordOfDayProvider);
    final foundAsync = ref.watch(wordOfDayFoundProvider);

    return wordOfDayAsync.when(
      data: (word) {
        final isFound = foundAsync.valueOrNull ?? false;
        
        return GestureDetector(
          onTap: () => _showWordOfDayDialog(context, word, isFound),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isFound 
                  ? Colors.green.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(SbRadius.secondary),
              border: Border.all(
                color: isFound ? Colors.green.shade700 : Colors.amber.shade700,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFound ? Icons.check_circle : Icons.stars,
                  size: 16,
                  color: isFound ? Colors.white : Colors.amber.shade800,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFound ? '¡Encontrada!' : 'Reto del día',
                      style: TextStyle(
                        color: isFound ? Colors.white : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      isFound ? word.esWord : word.hint,
                      style: TextStyle(
                        color: isFound 
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.amber.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showWordOfDayDialog(BuildContext context, WordOfDay word, bool isFound) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SbRadius.secondary),
        ),
        title: Row(
          children: [
            Icon(
              isFound ? Icons.check_circle : Icons.stars,
              color: isFound ? Colors.green : Colors.amber,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isFound ? '¡Reto completado!' : 'Reto del día',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFound) ...[
              Text(
                '¡Encontraste "${word.esWord}" (${word.enWord})!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vuelve mañana para un nuevo desafío.',
                style: TextStyle(color: Colors.grey),
              ),
            ] else ...[
              Text(
                'Busca y escanea: ${word.esWord}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pista: ${word.hint}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Categoría: ${word.categoryName}',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
