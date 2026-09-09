import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/sb_animations.dart';
import '../../../app/sb_colors.dart';
import '../../../app/sb_radius.dart';
import '../../object_recognition/domain/recognized_word.dart';
import '../data/gallery_repository.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String? _selectedCategory;

  static const _categories = [
    null, // "Todos"
    'objects',
    'animals',
    'food',
    'clothing',
    'nature',
    'vehicles',
    'technology',
  ];

  String _categoryLabel(String? cat) {
    switch (cat) {
      case null:
        return 'Todos';
      case 'objects':
        return 'Objetos';
      case 'animals':
        return 'Animales';
      case 'food':
        return 'Comida';
      case 'clothing':
        return 'Ropa';
      case 'nature':
        return 'Naturaleza';
      case 'vehicles':
        return 'Vehículos';
      case 'technology':
        return 'Tecnología';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Select the right stream based on category filter
    final itemsAsync = _selectedCategory == null
        ? ref.watch(galleryItemsProvider)
        : ref.watch(galleryByCategoryProvider(_selectedCategory!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        backgroundColor: SbColors.lightBlue,
        foregroundColor: SbColors.primaryText,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category filter chips
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(_categoryLabel(cat)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                  },
                  backgroundColor: SbColors.surface,
                  selectedColor: SbColors.accentBlue,
                  labelStyle: TextStyle(
                    color: SbColors.primaryText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: const BorderSide(color: SbColors.outline, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SbRadius.full),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),

          // Gallery grid
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyGalleryView(
                    hasFilter: _selectedCategory != null,
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SbFadeIn(
                      delay: Duration(milliseconds: index * 60),
                      child: _GalleryCard(
                        item: item,
                        onTap: () {
                          // Navigate to result screen with object data
                          final word = RecognizedWord(
                            enLabel: item.enLabel,
                            esLabel: item.esLabel,
                            confidence: 1.0,
                            photoPath: item.imageUrl ?? '',
                            timestamp: item.scannedAt,
                          );
                          context.push('/result', extra: {
                            'word': word,
                          });
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: SbLoadingDots()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: SbColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar la galería',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: SbColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A gallery card showing a scanned object thumbnail with labels.
class _GalleryCard extends StatelessWidget {
  final GalleryItem item;
  final VoidCallback onTap;

  const _GalleryCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat.yMMMd().format(item.scannedAt);

    return SbPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: SbColors.surface,
          borderRadius: BorderRadius.circular(SbRadius.secondary),
          border: Border.all(color: SbColors.outline, width: 1),
          boxShadow: const [SbShadows.soft],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image thumbnail
            Expanded(
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _PlaceholderImage(label: item.enLabel),
                    )
                  : _PlaceholderImage(label: item.enLabel),
            ),

            // Labels and date
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.enLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SbColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.esLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SbColors.primaryText.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: SbColors.primaryText.withValues(alpha: 0.5),
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

/// Placeholder when no image is available — shows the first letter of the label.
class _PlaceholderImage extends StatelessWidget {
  final String label;

  const _PlaceholderImage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SbColors.lightBlue,
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: SbColors.activeBlue,
          ),
        ),
      ),
    );
  }
}

/// Empty state when no items match the current filter.
class _EmptyGalleryView extends StatelessWidget {
  final bool hasFilter;

  const _EmptyGalleryView({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.filter_list_off : Icons.photo_library_outlined,
              size: 64,
              color: SbColors.accentBlue,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'No hay objetos en esta categoría'
                  : 'No hay objetos escaneados aún',
              style: theme.textTheme.titleMedium?.copyWith(
                color: SbColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 8),
              Text(
                'Toma una foto para empezar tu galería.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SbColors.primaryText.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Provider for filtering gallery items by category.
final galleryByCategoryProvider =
    StreamProvider.family<List<GalleryItem>, String>((ref, category) {
  return ref.watch(galleryRepositoryProvider).getGalleryByCategory(category);
});
