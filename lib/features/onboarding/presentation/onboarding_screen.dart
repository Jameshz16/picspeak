import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/nb_animations.dart';
import '../../../app/theme.dart';
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
          NbPressable(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Abrir configuración'),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
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
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  _StoryPage1(),
                  _StoryPage2(),
                  _StoryPage3(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => _DotIndicator(
                        isActive: index == _currentPage,
                        activeColor: _pageColors[_currentPage],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Main button
                  SizedBox(
                    width: double.infinity,
                    child: NbPressable(
                      child: ElevatedButton(
                        onPressed:
                            _isRequestingPermission ? null : _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pageColors[_currentPage],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(NbRadius.xs),
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
                                _currentPage == 2
                                    ? 'Abrir mis ojos'
                                    : 'Siguiente',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentPage < 2)
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

const _pageColors = [
  NbColors.primary,
  Color(0xFF4ECDC4),
  Color(0xFF9B59B6),
];

// ─── Story Page 1: The Vision ──────────────────────────────────────

class _StoryPage1 extends StatefulWidget {
  const _StoryPage1();

  @override
  State<_StoryPage1> createState() => _StoryPage1State();
}

class _StoryPage1State extends State<_StoryPage1>
    with SingleTickerProviderStateMixin {
  late final AnimationController _eyeController;
  late final Animation<double> _eyeOpen;

  @override
  void initState() {
    super.initState();
    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _eyeOpen = CurvedAnimation(
      parent: _eyeController,
      curve: Curves.easeOutBack,
    );
    // Start the eye-opening animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _eyeController.forward();
    });
  }

  @override
  void dispose() {
    _eyeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Eye opening animation
          AnimatedBuilder(
            animation: _eyeOpen,
            builder: (context, child) {
              final open = _eyeOpen.value;
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: NbColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomPaint(
                  painter: _EyePainter(open: open),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Title with fade-in
          NbPopIn(
            delay: const Duration(milliseconds: 600),
            child: const Text(
              'Imagina esto...',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: NbColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          NbPopIn(
            delay: const Duration(milliseconds: 900),
            child: Text(
              'Apuntas tu cámara a cualquier objeto y al instante sabes cómo se dice en inglés.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          NbPopIn(
            delay: const Duration(milliseconds: 1200),
            child: Text(
              'Cada objeto es una palabra que conquistas.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Story Page 2: The Discovery ───────────────────────────────────

class _StoryPage2 extends StatefulWidget {
  const _StoryPage2();

  @override
  State<_StoryPage2> createState() => _StoryPage2State();
}

class _StoryPage2State extends State<_StoryPage2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _blur;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _blur = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );
    // Start the reveal animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _revealController.forward();
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Object silhouette that reveals
          AnimatedBuilder(
            animation: _blur,
            builder: (context, child) {
              final blurAmount = 10.0 * (1.0 - _blur.value);
              return Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The "mystery" object icon
                      Icon(
                        Icons.question_mark_rounded,
                        size: 80,
                        color: const Color(0xFF4ECDC4).withValues(
                          alpha: 0.3 + (0.7 * _blur.value),
                        ),
                      ),
                      // Blur overlay that fades out
                      if (blurAmount > 0.5)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.8 * (1.0 - _blur.value),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          NbPopIn(
            delay: const Duration(milliseconds: 400),
            child: const Text(
              'Tu primer objeto te espera',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4ECDC4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          NbPopIn(
            delay: const Duration(milliseconds: 700),
            child: Text(
              'Mira a tu alrededor. Esa taza, esa silla, ese árbol fuera de la ventana...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          NbPopIn(
            delay: const Duration(milliseconds: 1000),
            child: Text(
              'Cada uno tiene un nombre en inglés esperándote.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Story Page 3: The Call to Action ──────────────────────────────

class _StoryPage3 extends StatefulWidget {
  const _StoryPage3();

  @override
  State<_StoryPage3> createState() => _StoryPage3State();
}

class _StoryPage3State extends State<_StoryPage3>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera icon with pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (0.05 * _pulseController.value);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 72,
                    color: Color(0xFF9B59B6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            '¿Listo para explorar?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9B59B6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Solo necesitamos acceso a tu cámara para que la magia comience.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Permission explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(NbRadius.xs),
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
          ),
        ],
      ),
    );
  }
}

// ─── Eye Painter ───────────────────────────────────────────────────

class _EyePainter extends CustomPainter {
  final double open;

  _EyePainter({required this.open});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Eye outline (almond shape)
    final eyePath = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radius * open,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * open,
        center.dx - radius,
        center.dy,
      );

    // Draw eye white
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(eyePath, eyePaint);

    // Draw eye outline
    final outlinePaint = Paint()
      ..color = NbColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(eyePath, outlinePaint);

    // Draw iris
    final irisRadius = radius * 0.45 * open;
    if (irisRadius > 2) {
      final irisPaint = Paint()
        ..color = NbColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, irisRadius, irisPaint);

      // Draw pupil
      final pupilRadius = irisRadius * 0.5;
      final pupilPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, pupilRadius, pupilPaint);

      // Draw highlight
      final highlightRadius = pupilRadius * 0.3;
      final highlightPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(center.dx - pupilRadius * 0.4, center.dy - pupilRadius * 0.4),
        highlightRadius,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_EyePainter oldDelegate) => oldDelegate.open != open;
}

// ─── Dot Indicator ─────────────────────────────────────────────────

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
