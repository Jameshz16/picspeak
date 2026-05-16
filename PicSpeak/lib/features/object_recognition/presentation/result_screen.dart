import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/tts_service.dart';
import '../../flashcard_review/data/flashcard_providers.dart';
import '../../word_history/data/history_providers.dart';
import '../domain/labeled_object.dart';
import '../domain/recognized_word.dart';
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

  @override
  void initState() {
    super.initState();
    _checkTtsAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyRepositoryProvider).log(widget.word);
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
      final exists = await repo.exists(widget.word.enLabel);
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
        await repo.save(widget.word);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speakingLocale = ref.watch(ttsPlayNotifierProvider);
    final hasTranslation = widget.word.esLabel != 'Traducción no disponible';

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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(widget.word.photoPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      widget.word.enLabel,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.word.esLabel,
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
                      'Confidence: ${(widget.word.confidence * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _TtsButton(
                    label: 'Escuchar en inglés',
                    locale: 'en-US',
                    text: widget.word.enLabel,
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
                    text: widget.word.esLabel,
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
            ElevatedButton.icon(
              onPressed: _isSaving || _isSaved ? null : _onFavorite,
              icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
              label: Text(
                _isSaved ? 'Saved to favorites' : 'Add to favorites',
              ),
            ),
            const SizedBox(height: 16),
            if (widget.allLabels.length > 1) ...[
              const Text(
                'Also recognized:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.allLabels.skip(1).map((label) {
                  return Chip(
                    label: Text(
                      '${label.label} (${(label.confidence * 100).toStringAsFixed(0)}%)',
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
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
