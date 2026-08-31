import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/nb_animations.dart';
import '../../../app/theme.dart';
import '../../../core/data/phrase_repository.dart';
import '../domain/template_phrases.dart';
import '../presentation/tts_play_notifier.dart';

/// Displays example phrases for a recognized word.
///
/// Curated phrases from the JSON asset are preferred. When none exist,
/// simple template-based phrases are generated so every word has at
/// least two example sentences.
class PhrasesSection extends ConsumerWidget {
  final String enLabel;
  final String esLabel;

  const PhrasesSection({
    super.key,
    required this.enLabel,
    required this.esLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(phraseRepositoryProvider);

    return repoAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (repo) {
        final phrases =
            repo.getPhrases(enLabel) ?? generateTemplatePhrases(enLabel, esLabel);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  size: 20,
                  color: NbColors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ejemplos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(phrases.length, (index) {
              return NbPopIn(
                delay: Duration(milliseconds: index * 60),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PhraseCard(
                    phrase: phrases[index],
                    onSpeak: () {
                      ref
                          .read(ttsPlayNotifierProvider.notifier)
                          .speak(phrases[index].en, 'en-US');
                    },
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _PhraseCard extends StatelessWidget {
  final PhrasePair phrase;
  final VoidCallback onSpeak;

  const _PhraseCard({required this.phrase, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(NbRadius.xs),
        border: Border.all(color: NbColors.outline, width: 2),
        boxShadow: const [NbShadows.hard],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phrase.en,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phrase.es,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NbPressable(
            child: IconButton(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: NbColors.primary.withValues(alpha: 0.1),
                foregroundColor: NbColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NbRadius.xs),
                  side: const BorderSide(color: NbColors.outline, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
