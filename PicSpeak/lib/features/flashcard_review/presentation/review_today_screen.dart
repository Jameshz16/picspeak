import 'dart:io';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tts_service.dart';
import '../../app_settings/data/settings_providers.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../../object_recognition/presentation/tts_play_notifier.dart';
import '../../stats/data/stats_repository.dart';
import '../domain/srs_engine.dart';
import '../data/flashcard_providers.dart';

class ReviewTodayScreen extends ConsumerStatefulWidget {
  const ReviewTodayScreen({super.key});

  @override
  ConsumerState<ReviewTodayScreen> createState() => _ReviewTodayScreenState();
}

class _ReviewTodayScreenState extends ConsumerState<ReviewTodayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  List<RecognizedWord> _dueCards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  bool _enAvailable = false;
  bool _esAvailable = false;
  int _reviewedCount = 0;
  bool _completionRecorded = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadDueCards();
    _checkTtsAvailability();
  }

  @override
  void dispose() {
    _recordCompletion();
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadDueCards() async {
    final repo = ref.read(flashcardRepositoryProvider);
    final dueCards = await repo.getDueCards();
    if (mounted) {
      setState(() {
        _dueCards = dueCards;
        _isLoading = false;
        _currentIndex = 0;
      });
    }
  }

  Future<void> _checkTtsAvailability() async {
    final tts = ref.read(ttsServiceProvider);
    final en = await tts.isLanguageAvailable('en-US');
    final es = await tts.isLanguageAvailable('es-ES');
    if (mounted) {
      setState(() {
        _enAvailable = en;
        _esAvailable = es;
      });
    }
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _rateCard(int quality) async {
    if (_currentIndex >= _dueCards.length) return;

    final card = _dueCards[_currentIndex];
    final result = SrsEngine.calculate(
      currentInterval: card.interval,
      currentEaseFactor: card.easeFactor,
      quality: quality,
    );

    // Update SRS data in repository
    final repo = ref.read(flashcardRepositoryProvider);
    await repo.updateSrs(
      enLabel: card.enLabel,
      interval: result.interval,
      easeFactor: result.easeFactor,
      nextReview: result.nextReview,
    );

    if (!mounted) return;

    setState(() {
      _reviewedCount++;
      _isFlipped = false;
    });
    _flipController.reset();

    // Move to next card
    if (_currentIndex < _dueCards.length - 1) {
      setState(() => _currentIndex++);
    } else {
      // All done — record study session for streak + reviewed count
      _recordCompletion();
      setState(() => _currentIndex = _dueCards.length);
    }
  }

  void _recordCompletion() {
    if (_reviewedCount <= 0 || _completionRecorded) return;
    _completionRecorded = true;
    final statsRepoAsync = ref.read(statsRepositoryProvider);
    if (statsRepoAsync.hasValue) {
      statsRepoAsync.value!.recordStudySession(reviewedCount: _reviewedCount);
    }
  }

  void _speakWithSpeed(String text, String locale, double speed) {
    Future<void> doIt() async {
      await ref.read(ttsServiceProvider).setSpeed(speed);
      ref.read(ttsPlayNotifierProvider.notifier).speak(text, locale);
    }
    doIt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final isSpanishPrimary = settingsAsync.valueOrNull?.locale == 'es';
    final voiceSpeed = settingsAsync.valueOrNull?.voiceSpeed ?? 1.0;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dueCards.isEmpty) {
      return _buildEmptyView(theme);
    }

    if (_currentIndex >= _dueCards.length) {
      return _buildCompletionView(theme);
    }

    final word = _dueCards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} de ${_dueCards.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_reviewedCount reviewed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe right → "Good" (quality 2)
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 200) {
            _rateCard(2);
          }
          // Swipe left → "Again" (quality 0)
          else if (details.primaryVelocity != null &&
              details.primaryVelocity! < -200) {
            _rateCard(0);
          }
        },
        onTap: _flipCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _dueCards.length,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 16),

              // Card
              Expanded(
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * pi;
                    final showBack = angle >= pi / 2;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(showBack ? angle - pi : angle),
                      alignment: Alignment.center,
                      child: showBack
                          ? _buildBackSide(word, theme, isSpanishPrimary, voiceSpeed)
                          : _buildFrontSide(word, theme, isSpanishPrimary, voiceSpeed),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // SRS Rating buttons
              if (_isFlipped) ...[
                Text(
                  'How well did you know this?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RatingButton(
                        label: 'Again',
                        icon: Icons.close,
                        color: Colors.red,
                        onPressed: () => _rateCard(0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RatingButton(
                        label: 'Hard',
                        icon: Icons.sentiment_dissatisfied,
                        color: Colors.orange,
                        onPressed: () => _rateCard(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RatingButton(
                        label: 'Good',
                        icon: Icons.sentiment_satisfied,
                        color: Colors.green,
                        onPressed: () => _rateCard(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RatingButton(
                        label: 'Easy',
                        icon: Icons.sentiment_very_satisfied,
                        color: Colors.blue,
                        onPressed: () => _rateCard(3),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Navigation when not flipped
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: _currentIndex > 0
                          ? () {
                              setState(() {
                                _currentIndex--;
                                _isFlipped = false;
                              });
                              _flipController.reset();
                            }
                          : null,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      'Tap to reveal',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        if (_currentIndex < _dueCards.length - 1) {
                          setState(() {
                            _currentIndex++;
                            _isFlipped = false;
                          });
                          _flipController.reset();
                        }
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide(
    RecognizedWord word,
    ThemeData theme,
    bool isSpanishPrimary,
    double voiceSpeed,
  ) {
    final speakingLocale = ref.watch(ttsPlayNotifierProvider);
    final labelText = isSpanishPrimary ? word.esLabel : word.enLabel;
    final ttsLocale = isSpanishPrimary ? 'es-ES' : 'en-US';
    final ttsLabel = isSpanishPrimary ? 'Escuchar en español' : 'Escuchar en inglés';
    final hasTranslation = word.esLabel != 'Sin traducción' &&
        word.esLabel != 'Traducción no disponible';
    final ttsAvailable = isSpanishPrimary ? _esAvailable && hasTranslation : _enAvailable;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Image.file(
              File(word.photoPath),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                labelText,
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _TtsButton(
              label: ttsLabel,
              locale: ttsLocale,
              text: labelText,
              available: ttsAvailable,
              isSpeaking: speakingLocale == ttsLocale,
              onSpeak: (text, locale) => _speakWithSpeed(text, locale, voiceSpeed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide(
    RecognizedWord word,
    ThemeData theme,
    bool isSpanishPrimary,
    double voiceSpeed,
  ) {
    final speakingLocale = ref.watch(ttsPlayNotifierProvider);
    final labelText = isSpanishPrimary ? word.enLabel : word.esLabel;
    final ttsLocale = isSpanishPrimary ? 'en-US' : 'es-ES';
    final ttsLabel = isSpanishPrimary ? 'Escuchar en inglés' : 'Escuchar en español';
    final hasTranslation = word.esLabel != 'Sin traducción' &&
        word.esLabel != 'Traducción no disponible';
    final ttsAvailable = isSpanishPrimary ? _enAvailable : _esAvailable && hasTranslation;

    // Show SRS info on the back
    final nextLabel = SrsEngine.nextReviewLabel(word.nextReview);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Image.file(
              File(word.photoPath),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labelText,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Next review: $nextLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _TtsButton(
              label: ttsLabel,
              locale: ttsLocale,
              text: labelText,
              available: ttsAvailable,
              isSpeaking: speakingLocale == ttsLocale,
              onSpeak: (text, locale) => _speakWithSpeed(text, locale, voiceSpeed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'All caught up!',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'No cards to review right now. Come back later or scan new words!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan new words'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/favorites'),
                icon: const Icon(Icons.favorite),
                label: const Text('View all favorites'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionView(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Complete'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Review completado!',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You reviewed $_reviewedCount cards. Great job!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan new words'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TtsButton extends StatelessWidget {
  final String label;
  final String locale;
  final String text;
  final bool available;
  final bool isSpeaking;
  final void Function(String text, String locale) onSpeak;

  const _TtsButton({
    required this.label,
    required this.locale,
    required this.text,
    required this.available,
    required this.isSpeaking,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: available
          ? label
          : 'Voice not available for this language',
      child: ElevatedButton.icon(
        onPressed: available && !isSpeaking
            ? () => onSpeak(text, locale)
            : null,
        icon: isSpeaking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.volume_up),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label),
        ),
      ),
    );
  }
}
