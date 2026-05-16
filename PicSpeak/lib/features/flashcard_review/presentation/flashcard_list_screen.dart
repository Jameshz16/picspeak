import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../object_recognition/domain/recognized_word.dart';
import '../data/flashcard_providers.dart';

class FlashcardListScreen extends ConsumerStatefulWidget {
  const FlashcardListScreen({super.key});

  @override
  ConsumerState<FlashcardListScreen> createState() =>
      _FlashcardListScreenState();
}

class _FlashcardListScreenState extends ConsumerState<FlashcardListScreen> {
  Future<List<RecognizedWord>> _loadFlashcards() async {
    final repo = ref.read(flashcardRepositoryProvider);
    return repo.loadAll();
  }

  Future<void> _removeFlashcard(String enLabel) async {
    final repo = ref.read(flashcardRepositoryProvider);
    await repo.remove(enLabel);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          FutureBuilder<List<RecognizedWord>>(
            future: _loadFlashcards(),
            builder: (context, snapshot) {
              final cards = snapshot.data ?? [];
              if (cards.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  context.push('/review?index=0');
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start review'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<RecognizedWord>>(
        future: _loadFlashcards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cards = snapshot.data ?? [];

          if (cards.isEmpty) {
            return const _EmptyFlashcardsView();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final word = cards[index];
              return Dismissible(
                key: ValueKey(word.enLabel),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove favorite?'),
                      content: Text(
                        'Remove "${word.enLabel}" from your favorites?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await _removeFlashcard(word.enLabel);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Removed "${word.enLabel}"')),
                    );
                  }
                },
                child: _FlashcardGridItem(
                  word: word,
                  onTap: () {
                    context.push('/review?index=$index');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FlashcardGridItem extends StatelessWidget {
  final RecognizedWord word;
  final VoidCallback onTap;

  const _FlashcardGridItem({
    required this.word,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Image.file(
                File(word.photoPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.enLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.esLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFlashcardsView extends StatelessWidget {
  const _EmptyFlashcardsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes flashcards!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Escanea un objeto y guárdalo como favorito.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
