import 'dart:io';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tts_service.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../../object_recognition/presentation/tts_play_notifier.dart';
import '../data/flashcard_providers.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const FlashcardReviewScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  List<RecognizedWord> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  bool _enAvailable = false;
  bool _esAvailable = false;

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
    _currentIndex = widget.initialIndex;
    _loadCards();
    _checkTtsAvailability();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final repo = ref.read(flashcardRepositoryProvider);
    final cards = await repo.loadAll();
    if (mounted) {
      setState(() {
        _cards = cards;
        _isLoading = false;
        if (_currentIndex >= cards.length) {
          _currentIndex = cards.isEmpty ? 0 : cards.length - 1;
        }
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

  void _nextCard() {
    if (_flipController.isAnimating) return;
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      _flipController.reset();
    }
  }

  void _previousCard() {
    if (_flipController.isAnimating) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
      _flipController.reset();
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
    });
    _flipController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentIndex >= _cards.length) {
      return _buildCompletionView(theme);
    }

    final word = _cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} de ${_cards.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -200) {
            _nextCard();
          } else if (details.primaryVelocity! > 200) {
            _previousCard();
          }
        },
        onTap: _flipCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                          ? _buildBackSide(word, theme)
                          : _buildFrontSide(word, theme),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _currentIndex > 0 ? _previousCard : null,
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed:
                        _currentIndex < _cards.length - 1 ? _nextCard : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide(RecognizedWord word, ThemeData theme) {
    final speakingLocale = ref.watch(ttsPlayNotifierProvider);

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
                word.enLabel,
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _TtsButton(
              label: 'Escuchar en inglés',
              locale: 'en-US',
              text: word.enLabel,
              available: _enAvailable,
              isSpeaking: speakingLocale == 'en-US',
              onSpeak: (text, locale) => ref
                  .read(ttsPlayNotifierProvider.notifier)
                  .speak(text, locale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide(RecognizedWord word, ThemeData theme) {
    final speakingLocale = ref.watch(ttsPlayNotifierProvider);
    final hasTranslation = word.esLabel != 'Traducción no disponible';

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
                word.esLabel,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _TtsButton(
              label: 'Escuchar en español',
              locale: 'es-ES',
              text: word.esLabel,
              available: _esAvailable && hasTranslation,
              isSpeaking: speakingLocale == 'es-ES',
              onSpeak: (text, locale) => ref
                  .read(ttsPlayNotifierProvider.notifier)
                  .speak(text, locale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionView(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
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
                Icons.check_circle,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Review completado!',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.replay),
                label: const Text('Restart review'),
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
