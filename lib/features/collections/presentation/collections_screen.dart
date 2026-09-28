import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/collections/presentation/providers/collections_providers.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available collection color presets
const List<Color> _collectionColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFFEC4899), // Pink
  Color(0xFF10B981), // Emerald
  Color(0xFFF59E0B), // Amber
  Color(0xFF3B82F6), // Blue
  Color(0xFFEF4444), // Red
  Color(0xFF8B5CF6), // Violet
  Color(0xFF14B8A6), // Teal
  Color(0xFFF97316), // Orange
  Color(0xFF6B7280), // Gray
];

/// Collections screen — manage document collections/folders.
class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final collectionsAsync = ref.watch(collectionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(LucideIcons.folder_plus),
        label: const Text('New Collection'),
      ),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (collections) {
          if (collections.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.folder_heart,
                      size: 36,
                      color: colorScheme.primary.withAlpha(140),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No Collections Yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Text(
                      'Organize your documents into collections\nfor quick access.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DocoraButton(
                    label: 'Create Collection',
                    icon: LucideIcons.folder_plus,
                    onPressed: () => _showCreateDialog(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: collections.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final collection = collections[index];
              final color = _parseColor(collection.colorHex);

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: color.withAlpha(50),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openCollection(context, ref, collection),
                  onLongPress: () =>
                      _showCollectionActions(context, ref, collection),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.folder,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collection.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${collection.documentCount} document${collection.documentCount == 1 ? '' : 's'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevron_right,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openCollection(
    BuildContext context,
    WidgetRef ref,
    DocumentCollection collection,
  ) {
    AppMotion.subtleHaptic();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CollectionDetailScreen(collection: collection),
      ),
    );
  }

  void _showCollectionActions(
    BuildContext context,
    WidgetRef ref,
    DocumentCollection collection,
  ) {
    AppMotion.subtleHaptic();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).padding.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              collection.name,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ref, collection);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash, color: AppColors.error500),
              title: Text(
                'Delete Collection',
                style: TextStyle(color: AppColors.error500),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(collectionsControllerProvider.notifier)
                    .deleteCollection(collection.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('"${collection.name}" deleted')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    DocumentCollection collection,
  ) {
    final controller = TextEditingController(text: collection.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Collection name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty && name != collection.name) {
                await ref
                    .read(collectionsControllerProvider.notifier)
                    .renameCollection(collection.id, name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int selectedColorIndex = 0;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(LucideIcons.folder_plus, size: 20),
              SizedBox(width: 8),
              Text('New Collection'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Collection name',
                  hintText: 'e.g., Work Reports, Tax Documents',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Color',
                style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_collectionColors.length, (i) {
                  final isSelected = selectedColorIndex == i;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _collectionColors[i],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(ctx).colorScheme.onSurface,
                                width: 2.5)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(LucideIcons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final colorHex = _collectionColors[selectedColorIndex]
                    .value
                    .toRadixString(16)
                    .padLeft(8, '0');
                await ref
                    .read(collectionsControllerProvider.notifier)
                    .createCollection(name: name, colorHex: colorHex);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail screen showing a collection's documents
class _CollectionDetailScreen extends ConsumerWidget {
  const _CollectionDetailScreen({required this.collection});
  final DocumentCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _parseColor(collection.colorHex);
    final docsAsync = ref.watch(collectionDocumentsProvider(collection.id));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.folder, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                collection.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.file_plus),
            tooltip: 'Add Document',
            onPressed: () => _addDocumentToCollection(context, ref),
          ),
        ],
      ),
      body: docsAsync.when(
        loading: () => ListView.builder(
          itemCount: 4,
          itemBuilder: (_, __) => const DocumentListItemSkeleton(),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.file_plus,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Collection is Empty',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Add documents from the file list to this collection.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DocoraButton(
                    label: 'Add Document',
                    icon: LucideIcons.file_plus,
                    size: DocoraButtonSize.small,
                    onPressed: () => _addDocumentToCollection(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Dismissible(
                key: ValueKey(doc.path),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  color: AppColors.error500.withAlpha(30),
                  child: const Icon(LucideIcons.trash, color: AppColors.error500),
                ),
                onDismissed: (_) {
                  ref
                      .read(collectionsControllerProvider.notifier)
                      .removeDocumentFromCollection(
                        collectionId: collection.id,
                        documentPath: doc.path,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${doc.name} removed from collection')),
                  );
                },
                child: DocumentListItem(
                  document: doc,
                  onTap: () {
                    AppMotion.subtleHaptic();
                    ref.read(filesControllerProvider.notifier).markOpened(doc);
                    DocumentOpener.open(context, doc.path);
                  },
                  onFavoriteToggle: () {
                    ref.read(filesControllerProvider.notifier).toggleFavorite(doc);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addDocumentToCollection(
    BuildContext context,
    WidgetRef ref,
  ) async {
    AppMotion.subtleHaptic();
    // Import files and add to collection
    final count = await ref
        .read(filesControllerProvider.notifier)
        .pickAndImportFiles();

    if (count > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count document(s)')),
      );
      // Refresh
      ref.invalidate(collectionDocumentsProvider(collection.id));
    }
  }
}

Color _parseColor(String hex) {
  try {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16));
  } catch (_) {
    return const Color(0xFF6366F1);
  }
}
