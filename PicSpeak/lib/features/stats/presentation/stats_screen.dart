import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text('My Progress'),
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, theme, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  label: 'Scanned',
                  value: stats.totalScanned.toString(),
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Favorites',
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
                  label: 'Due Today',
                  value: stats.dueToday.toString(),
                  icon: Icons.alarm,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Mastered',
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
                    'Mastery Progress',
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
                    '${stats.masteryPercent.toStringAsFixed(0)}% mastered (${stats.masteredCount}/${stats.totalFavorites} words)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          if (stats.dueToday > 0)
            ElevatedButton.icon(
              onPressed: () => context.push('/review-today'),
              icon: const Icon(Icons.school),
              label: Text('Review ${stats.dueToday} cards now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan new words'),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streakDays;

  const _StreakCard({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays day streak',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: streakDays > 0 ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  streakDays > 0
                      ? 'Keep it up! Study every day.'
                      : 'Study today to start a streak!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: streakDays > 0
                        ? Colors.white.withValues(alpha: 0.9)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
