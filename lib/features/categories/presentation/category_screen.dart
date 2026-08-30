import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/nb_animations.dart';
import '../../../app/theme.dart';
import '../../../core/data/label_map_repository.dart';
import '../../../core/data/word_category.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../../flashcard_review/data/flashcard_providers.dart';
import '../data/category_progress_repository.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final labelMapAsync = ref.watch(labelMapProvider);
    final progressAsync = ref.watch(categoryProgressProvider);
    final statsAsync = ref.watch(categoryStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: labelMapAsync.when(
        data: (repo) {
          final categories = repo.getCategories();
          final progressList = progressAsync.valueOrNull ?? [];
          final stats = statsAsync.valueOrNull;

          return Column(
            children: [
              // Stats header
              if (stats != null) _StatsHeader(stats: stats),
              
              // Category grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final progress = progressList
                        .where((p) => p.categoryId == cat.id)
                        .firstOrNull;
                    
                    return NbPopIn(
                      delay: Duration(milliseconds: index * 60),
                      child: _CategoryCard(
                        category: cat,
                        wordCount: repo.getWordsInCategory(cat.id).length,
                        progress: progress,
                        onTap: () {
                          context.push('/category/${cat.id}');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: NbLoadingBlock()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

/// Stats header showing overall category progression.
class _StatsHeader extends StatelessWidget {
  final CategoryStats stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(NbRadius.xs),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            size: 32,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.narrativeMessage,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalWordsScanned} palabras descubiertas en ${stats.totalCategories} categorías',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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

class _CategoryCard extends StatelessWidget {
  final WordCategory category;
  final int wordCount;
  final CategoryProgress? progress;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.wordCount,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _getIconData(category.icon);
    final scannedWords = progress?.scannedWords ?? 0;
    final percent = progress?.percent ?? 0;
    final isUnlocked = progress?.isUnlocked ?? false;
    final isCompleted = progress?.isCompleted ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with badge indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        iconData,
                        size: 40,
                        color: isUnlocked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      if (isUnlocked)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.nameEs,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? Colors.green
                            : isUnlocked
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Progress text
                  Text(
                    '$scannedWords/$wordCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Completed overlay
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '¡Dominada!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
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
    final progressAsync = ref.watch(categoryProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryName(categoryId)),
      ),
      body: labelMapAsync.when(
        data: (repo) {
          final words = repo.getWordsInCategory(categoryId);
          final progressList = progressAsync.valueOrNull ?? [];
          final progress = progressList
              .where((p) => p.categoryId == categoryId)
              .firstOrNull;

          if (words.isEmpty) {
            return const Center(
              child: Text('Aún no hay palabras en esta categoría.'),
            );
          }

          return Column(
            children: [
              // Progress header
              if (progress != null) _CategoryProgressHeader(progress: progress),
              
              // Word list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final entry = words[index];
                    return NbPopIn(
                      delay: Duration(milliseconds: index * 60),
                      child: _WordTile(
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
                                  content: Text('"${entry.key}" agregado a favoritos!'),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ya está en favoritos.'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: NbLoadingBlock()),
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

/// Progress header for a specific category.
class _CategoryProgressHeader extends StatelessWidget {
  final CategoryProgress progress;

  const _CategoryProgressHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: progress.isUnlocked
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(NbRadius.xs),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                progress.isUnlocked ? Icons.emoji_events : Icons.explore,
                size: 24,
                color: progress.isUnlocked
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress.narrativeMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: progress.isUnlocked
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.percent / 100,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isCompleted
                    ? Colors.green
                    : progress.isUnlocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.scannedWords} de ${progress.totalWords} palabras',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: progress.isUnlocked
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${progress.percent}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progress.isUnlocked
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          tooltip: 'Agregar a favoritos',
        ),
      ),
    );
  }
}
