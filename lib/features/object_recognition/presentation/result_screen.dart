import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/nb_animations.dart';
import '../../../app/theme.dart';
import '../../../core/data/label_map_repository.dart';
import '../../../core/services/tts_service.dart';
import '../../flashcard_review/data/flashcard_providers.dart';
import '../../word_history/data/history_providers.dart';
import '../domain/labeled_object.dart';
import '../domain/recognized_word.dart';
import 'object_overlay.dart';
import 'scan_animations.dart';
import 'tts_play_notifier.dart';


class ResultScreen extends ConsumerStatefulWidget {
  final RecognizedWord word;
  final List<LabeledObject> allLabels;
  final bool isWordOfDay;

  const ResultScreen({
    super.key,
    required this.word,
    this.allLabels = const [],
    this.isWordOfDay = false,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _enAvailable = false;
  bool _esAvailable = false;
  bool _isSaving = false;
  bool _isSaved = false;
  bool _wordRevealed = false;
  late RecognizedWord _currentWord;

  @override
  void initState() {
    super.initState();
    _currentWord = widget.word;
    _checkTtsAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyRepositoryProvider).log(_currentWord);
    });
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

  Future<void> _onFavorite() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(flashcardRepositoryProvider);
      final exists = await repo.exists(_currentWord.enLabel);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lens ya la tiene guardada ✨'),
            ),
          );
        }
        setState(() => _isSaved = true);
      } else {
        await repo.save(_currentWord);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lens lo recordará por ti ❤️')),
          );
          setState(() => _isSaved = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving favorite: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _selectLabel(LabeledObject label) async {
    final labelMapRepo = await ref.read(labelMapProvider.future);
    final esTranslation = labelMapRepo.translate(label.label);
    final newWord = RecognizedWord(
      enLabel: label.label,
      esLabel: esTranslation ?? RecognizedWord.noTranslationSentinel,
      confidence: label.confidence,
      photoPath: _currentWord.photoPath,
      timestamp: DateTime.now(),
      boundingBox: label.boundingBox,
    );
    setState(() {
      _currentWord = newWord;
      _isSaved = false;
    });
    // Log to history
    ref.read(historyRepositoryProvider).log(newWord);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speakingLocale = ref.watch(ttsPlayNotifierProvider);
    final hasTranslation =
        _currentWord.esLabel != RecognizedWord.noTranslationSentinel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubrimiento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo with overlay + scanning line animation
            ClipRRect(
              borderRadius: BorderRadius.circular(NbRadius.xs),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ObjectOverlay(
                      photoPath: _currentWord.photoPath,
                      boundingBox: _currentWord.boundingBox,
                    ),
                    const ScanLineOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Word of the Day celebration
            if (widget.isWordOfDay) ...[
              NbPopIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade400,
                        Colors.orange.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(NbRadius.xs),
                    border: Border.all(color: Colors.amber.shade700, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 32,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Reto del día completado!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Encontraste la palabra del día',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Primary word card — floats like the Stitch label
            FloatingLabel(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      NbTypewriter(
                        text: _currentWord.enLabel,
                        style: theme.textTheme.headlineMedium,
                        duration: const Duration(milliseconds: 350),
                        onComplete: () {
                          if (mounted) setState(() => _wordRevealed = true);
                        },
                      ),
                      const SizedBox(height: 8),
                      // Spanish translation fades in after typewriter
                      AnimatedOpacity(
                        opacity: _wordRevealed ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Text(
                              _currentWord.esLabel,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: hasTranslation
                                    ? theme.colorScheme.secondary
                                    : Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!hasTranslation) ...[
                              const SizedBox(height: 8),
                              Chip(
                                label: const Text(RecognizedWord.noTranslationSentinel),
                                backgroundColor: Colors.orange.shade100,
                              ),
                            ],
                            const SizedBox(height: 12),
                            const SizedBox(height: 4),
                            _ConfidenceChip(confidence: _currentWord.confidence),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // TTS buttons
            Row(
              children: [
                Expanded(
                  child: _TtsButton(
                    label: 'Escuchar en inglés',
                    locale: 'en-US',
                    text: _currentWord.enLabel,
                    available: _enAvailable,
                    isSpeaking: speakingLocale == 'en-US',
                    onSpeak: (text, locale) => ref
                        .read(ttsPlayNotifierProvider.notifier)
                        .speak(text, locale),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TtsButton(
                    label: 'Escuchar en español',
                    locale: 'es-ES',
                    text: _currentWord.esLabel,
                    available: _esAvailable && hasTranslation,
                    isSpeaking: speakingLocale == 'es-ES',
                    onSpeak: (text, locale) => ref
                        .read(ttsPlayNotifierProvider.notifier)
                        .speak(text, locale),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Favorite button
            NbPressable(
              child: ElevatedButton.icon(
                onPressed: _isSaving || _isSaved ? null : _onFavorite,
                icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
                label: Text(
                  _isSaved ? 'Guardado' : 'Guardar como favorito',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Other recognized labels — tappable to switch
            if (widget.allLabels.length > 1) ...[
              const Text(
                'También podría ser:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.allLabels.skip(1).take(5).map((label) {
                  final isSelected = label.label == _currentWord.enLabel;
                  return ChoiceChip(
                    label: Text(
                      '${label.label} (${(label.confidence * 100).toStringAsFixed(0)}%)',
                    ),
                    selected: isSelected,
                    onSelected: isSelected ? null : (_) => _selectLabel(label),
                    selectedColor: theme.colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Scan again
            NbPressable(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Descubrir otro objeto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small decorative confidence chip — low prominence, not a primary feature.
class _ConfidenceChip extends StatelessWidget {
  final double confidence;

  const _ConfidenceChip({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (confidence * 100).round();

    final (label, color) = switch (percent) {
      >= 90 => ('¡Lens está seguro!', Colors.green),
      >= 70 => ('Lens cree que es...', Colors.blue),
      >= 50 => ('¿Será un...?', Colors.orange),
      _ => ('Intenta de nuevo', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label  $percent%',
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
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
      child: NbPressable(
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
      ),
    );
  }
}
