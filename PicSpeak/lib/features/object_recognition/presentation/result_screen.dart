import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/label_map_repository.dart';
import '../../../core/services/tts_service.dart';
import '../../flashcard_review/data/flashcard_providers.dart';
import '../../word_history/data/history_providers.dart';
import '../domain/labeled_object.dart';
import '../domain/recognized_word.dart';
import 'object_overlay.dart';
import 'tts_play_notifier.dart';


class ResultScreen extends ConsumerStatefulWidget {
  final RecognizedWord word;
  final List<LabeledObject> allLabels;

  const ResultScreen({
    super.key,
    required this.word,
    this.allLabels = const [],
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _enAvailable = false;
  bool _esAvailable = false;
  bool _isSaving = false;
  bool _isSaved = false;
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
              content: Text('This word is already in your favorites.'),
            ),
          );
        }
        setState(() => _isSaved = true);
      } else {
        await repo.save(_currentWord);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites!')),
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
      esLabel: esTranslation ?? 'Sin traducción',
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
    final hasTranslation = _currentWord.esLabel != 'Sin traducción' &&
        _currentWord.esLabel != 'Traducción no disponible';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
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
            // Photo with overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ObjectOverlay(
                  photoPath: _currentWord.photoPath,
                  boundingBox: _currentWord.boundingBox,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Primary word card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _currentWord.enLabel,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
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
                        label: const Text('Sin traducción'),
                        backgroundColor: Colors.orange.shade100,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Confidence: ${(_currentWord.confidence * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
            ElevatedButton.icon(
              onPressed: _isSaving || _isSaved ? null : _onFavorite,
              icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
              label: Text(
                _isSaved ? 'Saved to favorites' : 'Add to favorites',
              ),
            ),
            const SizedBox(height: 16),

            // Other recognized labels — tappable to switch
            if (widget.allLabels.length > 1) ...[
              const Text(
                'Also recognized:',
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
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan again'),
            ),
          ],
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
