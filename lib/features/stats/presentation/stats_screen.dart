import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sb_animations.dart';
import '../../../app/sb_radius.dart';
import '../../categories/data/category_progress_repository.dart';
import '../data/stats_repository.dart';
import '../domain/learning_stats.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(learningStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Historia'),
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, theme, stats),
        loading: () => const Center(child: SbLoadingDots()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, LearningStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Streak card
          _StreakCard(streakDays: stats.streakDays),
          const SizedBox(height: 16),

          // Summary row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Descubiertas',
                  value: stats.totalScanned.toString(),
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Favoritas',
                  value: stats.totalFavorites.toString(),
                  icon: Icons.favorite,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Por repasar',
                  value: stats.dueToday.toString(),
                  icon: Icons.alarm,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Dominadas',
                  value: stats.masteredCount.toString(),
                  icon: Icons.star,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mastery progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progreso de dominio',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: stats.masteryPercent / 100,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.masteryPercent.toStringAsFixed(0)}% dominado (${stats.masteredCount}/${stats.totalFavorites} palabras)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category badges
          _CategoryBadgesSection(),
          const SizedBox(height: 16),

          // Quick actions
if (stats.dueToday > 0)
            SbPressable(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/review-today'),
                icon: const Icon(Icons.school),
                label: Text('Repasar ${stats.dueToday} palabras ahora'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          const SizedBox(height: 12),

SbPressable(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Descubrir nuevas palabras'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streakDays;

  const _StreakCard({required this.streakDays});

  static String _levelName(int days) => switch (days) {
        0 => 'Explorador novato',
        <= 2 => 'Primeras miradas',
        <= 6 => 'Curioso constante',
        <= 13 => 'Cazador de palabras',
        <= 29 => 'Bilingüe en camino',
        _ => 'Leyenda PicSpeak',
      };

  static String _levelMessage(int days) => switch (days) {
        0 => 'Tu primera mirada te espera',
        1 => '¡Tu primera racha! Sigue así',
        <= 6 => 'Cada día sumas más palabras',
        <= 13 => 'Tu vocabulario crece rápido',
        <= 29 => '¡Imparable! El inglés es tuyo',
        _ => 'Dominas el mundo de las palabras',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
borderRadius: BorderRadius.circular(SbRadius.secondary),
          gradient: streakDays > 0
              ? LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.deepOrange.shade400,
                  ],
                )
              : null,
          color: streakDays == 0 ? theme.colorScheme.surfaceContainerHighest : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 48,
              color: streakDays > 0 ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _levelName(streakDays),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: streakDays > 0 ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streakDays > 0
                        ? '${streakDays}d · ${_levelMessage(streakDays)}'
                        : _levelMessage(streakDays),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: streakDays > 0
                          ? Colors.white.withValues(alpha: 0.9)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section showing category badges in the stats screen.
class _CategoryBadgesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(categoryProgressProvider);

    return progressAsync.when(
      data: (progressList) {
        final unlocked = progressList.where((p) => p.isUnlocked).toList();
        final inProgress = progressList
            .where((p) => !p.isUnlocked && p.scannedWords > 0)
            .toList();

        if (unlocked.isEmpty && inProgress.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 24,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sellos de categoría',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Unlocked badges
                if (unlocked.isNotEmpty) ...[
                  Text(
                    'Desbloqueados',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: unlocked.map((p) => _BadgeChip(
                      progress: p,
                      isUnlocked: true,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // In progress
                if (inProgress.isNotEmpty) ...[
                  Text(
                    'En progreso',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: inProgress.map((p) => _BadgeChip(
                      progress: p,
                      isUnlocked: false,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// A single badge chip showing category progress.
class _BadgeChip extends StatelessWidget {
  final CategoryProgress progress;
  final bool isUnlocked;

  const _BadgeChip({
    required this.progress,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _getIconData(progress.categoryIcon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Colors.amber.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? Colors.amber : theme.colorScheme.outlineVariant,
          width: isUnlocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 16,
            color: isUnlocked ? Colors.amber.shade800 : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            progress.categoryName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.amber.shade900 : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isUnlocked) ...[
            const SizedBox(width: 4),
            Text(
              '${progress.scannedWords}/${progress.totalWords}',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
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
