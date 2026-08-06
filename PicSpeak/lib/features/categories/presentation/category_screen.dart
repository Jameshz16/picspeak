import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/label_map_repository.dart';
import '../../../core/data/word_category.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../../flashcard_review/data/flashcard_providers.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final labelMapAsync = ref.watch(labelMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: labelMapAsync.when(
        data: (repo) {
          final categories = repo.getCategories();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryCard(
                category: cat,
                wordCount: repo.getWordsInCategory(cat.id).length,
                onTap: () {
                  context.push('/category/${cat.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

}

class _CategoryCard extends StatelessWidget {
  final WordCategory category;
  final int wordCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.wordCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _getIconData(category.icon);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconData,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                category.nameEs,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$wordCount words',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'pets': Icons.pets,
      'restaurant': Icons.restaurant,
      'checkroom': Icons.checkroom,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'nature': Icons.nature,
      'devices': Icons.devices,
      'accessibility_new': Icons.accessibility_new,
      'music_note': Icons.music_note,
      'sports_soccer': Icons.sports_soccer,
      'location_city': Icons.location_city,
      'build': Icons.build,
      'toys': Icons.toys,
      'explore': Icons.explore,
      'more_horiz': Icons.more_horiz,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

/// Screen showing words in a specific category.
class CategoryWordsScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryWordsScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final labelMapAsync = ref.watch(labelMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryName(categoryId)),
      ),
      body: labelMapAsync.when(
        data: (repo) {
          final words = repo.getWordsInCategory(categoryId);
          if (words.isEmpty) {
            return const Center(
              child: Text('No words in this category yet.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: words.length,
            itemBuilder: (context, index) {
              final entry = words[index];
              return _WordTile(
                enWord: entry.key,
                esWord: entry.value,
                onAddFavorite: () async {
                  final flashcardRepo = ref.read(flashcardRepositoryProvider);
                  final word = RecognizedWord(
                    enLabel: entry.key,
                    esLabel: entry.value,
                    confidence: 1.0,
                    photoPath: '', // No photo for manual adds
                    timestamp: DateTime.now(),
                  );
                  final exists = await flashcardRepo.exists(entry.key);
                  if (!exists) {
                    await flashcardRepo.save(word);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "${entry.key}" to favorites!'),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Already in favorites.'),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    const names = {
      'animals': 'Animales',
      'food': 'Comida',
      'clothing': 'Ropa',
      'home': 'Hogar',
      'vehicles': 'Vehículos',
      'nature': 'Naturaleza',
      'technology': 'Tecnología',
      'body': 'Cuerpo',
      'music': 'Música',
      'sports': 'Deportes',
      'buildings': 'Edificios',
      'tools': 'Herramientas',
      'toys_kids': 'Juguetes',
      'places': 'Lugares',
      'other': 'Otros',
    };
    return names[categoryId] ?? categoryId;
  }

}

class _WordTile extends StatelessWidget {
  final String enWord;
  final String esWord;
  final VoidCallback onAddFavorite;

  const _WordTile({
    required this.enWord,
    required this.esWord,
    required this.onAddFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            enWord[0],
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          enWord,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          esWord,
          style: TextStyle(color: theme.colorScheme.secondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: onAddFavorite,
          tooltip: 'Add to favorites',
        ),
      ),
    );
  }
}
