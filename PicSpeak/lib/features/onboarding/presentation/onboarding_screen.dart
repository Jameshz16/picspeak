import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/permission_service.dart';
import '../data/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingPermission = false;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: '¡Bienvenido a PicSpeak!',
      description:
          'Apunta la cámara a cualquier objeto y descubre su nombre en inglés y español',
      icon: Icons.camera_alt,
      color: Color(0xFFFF8C42),
    ),
    _OnboardingPageData(
      title: '¿Cómo funciona?',
      description:
          '1) Toma foto → 2) Ve el nombre en ambos idiomas → 3) Escucha la pronunciación → 4) Guarda tus favoritos como flashcards',
      icon: Icons.lightbulb,
      color: Color(0xFF4ECDC4),
    ),
    _OnboardingPageData(
      title: '¡Empecemos!',
      description:
          'Necesitamos acceso a tu cámara para identificar objetos',
      icon: Icons.camera_enhance,
      color: Color(0xFF9B59B6),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Future<void> _completeOnboarding() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.markOnboardingSeen();
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _isRequestingPermission = true);
    try {
      final service = ref.read(permissionServiceProvider);
      await service.requestCameraPermission();
      final granted = await service.isCameraPermissionGranted;
      if (mounted) {
        if (granted) {
          await _completeOnboarding();
        } else {
          _showPermissionDeniedDialog();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Necesitamos la cámara!'),
        content: const Text(
          'Sin cámara no podemos identificar objetos. Por favor, permite el acceso en la configuración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _requestCameraPermission();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _pages[index],
                    isLastPage: index == _pages.length - 1,
                    onRequestPermission: _requestCameraPermission,
                    isRequestingPermission: _isRequestingPermission,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _DotIndicator(
                        isActive: index == _currentPage,
                        activeColor: _pages[_currentPage].color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isRequestingPermission ? null : _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isRequestingPermission
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentPage == _pages.length - 1
                                  ? 'Permitir cámara'
                                  : 'Siguiente',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _onSkip,
                      child: const Text(
                        'Saltar',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  else
                    const SizedBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isLastPage;
  final VoidCallback onRequestPermission;
  final bool isRequestingPermission;

  const _OnboardingPage({
    required this.data,
    required this.isLastPage,
    required this.onRequestPermission,
    required this.isRequestingPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 72,
              color: data.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (isLastPage) ...[
            const SizedBox(height: 32),
            _buildPermissionExplanation(),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Usamos la cámara solo para identificar objetos. No guardamos fotos sin tu permiso.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final Color activeColor;

  const _DotIndicator({
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}
