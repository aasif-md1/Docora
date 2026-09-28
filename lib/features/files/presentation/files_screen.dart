import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/storage_permission_service.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/files/presentation/widgets/file_details_dialog.dart';
import 'package:docora/features/files/presentation/widgets/rename_dialog.dart';
import 'package:docora/features/files/presentation/widgets/sort_bottom_sheet.dart';
import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

/// Full-featured, offline File Manager tab for Docora.
/// Supports reactive search, format filtering with live counts, sorting,
/// batch selection, rename, delete to recycle bin, file details, and storage scanning.
class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onDocumentTap(DocumentEntity doc) {
    ref.read(filesControllerProvider.notifier).markOpened(doc);
    DocumentOpener.open(context, doc.path);
  }

  void _showDocumentActions(DocumentEntity doc) {
    final format = DocumentFormat.fromExtension(doc.extension);

    DocoraBottomSheet.show<void>(
      context: context,
      title: doc.name,
      subtitle: '${doc.formattedSize} • ${format.label}',
      showCloseButton: true,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DocoraActionTile(
            icon: LucideIcons.external_link,
            title: 'Open with External App',
            subtitle: 'Choose application on device',
            onTap: () {
              Navigator.pop(sheetCtx);
              OpenFile.open(doc.path);
            },
          ),
          DocoraActionTile(
            icon: LucideIcons.share_2,
            title: 'Share File',
            subtitle: 'Send via system share sheet',
            onTap: () {
              Navigator.pop(sheetCtx);
              Share.shareXFiles([XFile(doc.path)], text: doc.name);
            },
          ),
          DocoraActionTile(
            icon: LucideIcons.pencil,
            title: 'Rename File',
            onTap: () async {
              Navigator.pop(sheetCtx);
              final newName = await RenameDialog.show(context, doc);
              if (newName != null && newName != doc.name && mounted) {
                try {
                  await ref
                      .read(filesControllerProvider.notifier)
                      .renameDocument(doc, newName);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Renamed to $newName')),
                    );
                  }
                } on Object catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error renaming file: $e')),
                    );
                  }
                }
              }
            },
          ),
          DocoraActionTile(
            icon: doc.isFavorite
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            title: doc.isFavorite ? 'Remove Favorite' : 'Mark Favorite',
            iconColor: doc.isFavorite ? const Color(0xFFF59E0B) : null,
            onTap: () {
              Navigator.pop(sheetCtx);
              ref.read(filesControllerProvider.notifier).toggleFavorite(doc);
            },
          ),
          DocoraActionTile(
            icon: LucideIcons.info,
            title: 'File Details',
            subtitle: 'View size, path, date & checksum',
            onTap: () {
              Navigator.pop(sheetCtx);
              FileDetailsDialog.show(context, doc);
            },
          ),
          const Divider(height: 1),
          DocoraActionTile(
            icon: LucideIcons.trash,
            title: 'Move to Trash',
            subtitle: 'Retrievable from Recycle Bin for 30 days',
            isDestructive: true,
            onTap: () async {
              Navigator.pop(sheetCtx);
              await ref
                  .read(filesControllerProvider.notifier)
                  .moveToRecycleBin(doc);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${doc.name} moved to Trash'),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan() async {
    final granted =
        await StoragePermissionService.showRationaleSheet(context);
    if (!granted) return;

    final service = ref.read(storagePermissionServiceProvider);
    final status = await service.requestPermission();
    if (status != StoragePermissionState.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Storage permission is required to discover files.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: service.openSettings,
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final count = await ref
          .read(filesControllerProvider.notifier)
          .scanDeviceStorage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Discovered $count documents on device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final docsAsync = ref.watch(documentsStreamProvider);
    final categoryCountsAsync = ref.watch(categoryCountsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final currentSort = ref.watch(documentSortProvider);
    final isGridView = ref.watch(isGridViewProvider);
    final isScanning = ref.watch(isScanningProvider);
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedIds = ref.watch(selectedDocumentIdsProvider);
    final permissionAsync = ref.watch(storagePermissionStateProvider);

    final counts = categoryCountsAsync.valueOrNull ?? {};

    // Construct filter chip items with live counts
    final filterItems = FilterChipItem.defaultFilters.map((item) {
      final count = counts[item.id.toLowerCase()];
      return FilterChipItem(
        id: item.id,
        label: item.label,
        icon: item.icon,
        format: item.format,
        count: count,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
            ? Text('${selectedIds.length} Selected')
            : const Text('Files'),
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(LucideIcons.check_check),
              tooltip: 'Select All',
              onPressed: () {
                AppMotion.subtleHaptic();
                final allDocs = docsAsync.valueOrNull ?? [];
                final allIds = allDocs.map((d) => d.id).toSet();
                ref.read(selectedDocumentIdsProvider.notifier).state = allIds;
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.star),
              tooltip: 'Favorite Selected',
              onPressed: () {
                AppMotion.subtleHaptic();
                final allDocs = docsAsync.valueOrNull ?? [];
                ref
                    .read(filesControllerProvider.notifier)
                    .batchSetFavorite(allDocs, isFavorite: true);
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash),
              tooltip: 'Delete Selected',
              onPressed: () {
                AppMotion.subtleHaptic();
                final allDocs = docsAsync.valueOrNull ?? [];
                ref
                    .read(filesControllerProvider.notifier)
                    .batchDelete(allDocs);
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.x),
              tooltip: 'Exit Selection',
              onPressed: () {
                AppMotion.subtleHaptic();
                ref.read(isSelectionModeProvider.notifier).state = false;
                ref.read(selectedDocumentIdsProvider.notifier).state = {};
              },
            ),
          ] else ...[
            // View Mode Toggle
            IconButton(
              icon: Icon(
                isGridView ? LucideIcons.list : LucideIcons.layout_grid,
              ),
              tooltip: isGridView ? 'List view' : 'Grid view',
              onPressed: () {
                AppMotion.subtleHaptic();
                ref.read(isGridViewProvider.notifier).state = !isGridView;
              },
            ),
            // Sort Trigger
            IconButton(
              icon: const Icon(LucideIcons.arrow_down_up),
              tooltip: 'Sort options',
              onPressed: () {
                SortBottomSheet.show(
                  context: context,
                  currentSort: currentSort,
                  onSortSelected: (sort) {
                    ref.read(documentSortProvider.notifier).state = sort;
                  },
                );
              },
            ),
            // Multi-select toggle
            IconButton(
              icon: const Icon(LucideIcons.list_checks),
              tooltip: 'Select multiple',
              onPressed: () {
                AppMotion.subtleHaptic();
                ref.read(isSelectionModeProvider.notifier).state = true;
                ref.read(selectedDocumentIdsProvider.notifier).state = {};
              },
            ),
            // Scan / Import Menu
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.ellipsis_vertical),
              tooltip: 'More options',
              onSelected: (val) {
                if (val == 'scan') {
                  _handleScan();
                } else if (val == 'import') {
                  ref
                      .read(filesControllerProvider.notifier)
                      .pickAndImportFiles();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'scan',
                  child: Row(
                    children: [
                      Icon(LucideIcons.scan_line, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Scan Device Storage'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(LucideIcons.file_plus, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Import Files'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Scanning Progress Indicator
          if (isScanning)
            const LinearProgressIndicator(minHeight: 3),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: DocoraSearchField(
              controller: _searchController,
              hintText: 'Search documents by name or tag...',
              onChanged: (query) {
                ref.read(searchQueryProvider.notifier).state = query;
              },
              onFilterTap: () {
                SortBottomSheet.show(
                  context: context,
                  currentSort: currentSort,
                  onSortSelected: (sort) {
                    ref.read(documentSortProvider.notifier).state = sort;
                  },
                );
              },
            ),
          ),

          // Format Filter Chip Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: FilterChipBar(
              selectedId: selectedCategory,
              items: filterItems,
              onSelected: (id) {
                ref.read(selectedCategoryProvider.notifier).state = id;
              },
            ),
          ),

          // Permission Request Banner (if not yet granted)
          permissionAsync.maybeWhen(
            data: (state) {
              if (state != StoragePermissionState.granted) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.shield_alert,
                          color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Grant storage permission to index all documents on your device.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      DocoraButton(
                        label: 'Grant',
                        size: DocoraButtonSize.small,
                        onPressed: _handleScan,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Main Documents List / Grid / States
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(filesControllerProvider.notifier)
                    .scanDeviceStorage();
              },
              child: docsAsync.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: 8,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (_, __) => const DocumentListItemSkeleton(),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading documents: $err'),
                ),
                data: (docs) {
                  if (docs.isEmpty) {
                    final isSearching =
                        ref.watch(searchQueryProvider).trim().isNotEmpty;
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: DocoraEmptyState(
                          icon: isSearching
                              ? LucideIcons.search_x
                              : LucideIcons.folder_search,
                          title: isSearching
                              ? 'No Documents Found'
                              : 'No Documents Indexed',
                          description: isSearching
                              ? 'Try searching with a different term or clear the filter.'
                              : 'Tap below to scan your device for documents or import files.',
                          actionLabel: isSearching
                              ? 'Clear Search'
                              : 'Scan Device Storage',
                          actionIcon: isSearching
                              ? LucideIcons.x
                              : LucideIcons.scan_line,
                          onAction: () {
                            if (isSearching) {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state =
                                  '';
                            } else {
                              _handleScan();
                            }
                          },
                        ),
                      ),
                    );
                  }

                  if (isGridView) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return DocumentGridItem(
                          document: doc,
                          isSelected: selectedIds.contains(doc.id),
                          isSelectionMode: isSelectionMode,
                          onTap: () => _onDocumentTap(doc),
                          onLongPress: () {
                            ref
                                .read(isSelectionModeProvider.notifier)
                                .state = true;
                            ref
                                .read(selectedDocumentIdsProvider.notifier)
                                .state = {doc.id};
                          },
                          onSelectChanged: (val) {
                            final current = Set<int>.from(selectedIds);
                            if (val == true) {
                              current.add(doc.id);
                            } else {
                              current.remove(doc.id);
                            }
                            ref
                                .read(selectedDocumentIdsProvider.notifier)
                                .state = current;
                          },
                          onFavoriteToggle: () {
                            ref
                                .read(filesControllerProvider.notifier)
                                .toggleFavorite(doc);
                          },
                          onMorePressed: () => _showDocumentActions(doc),
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return DocumentListItem(
                        document: doc,
                        isSelected: selectedIds.contains(doc.id),
                        isSelectionMode: isSelectionMode,
                        onTap: () => _onDocumentTap(doc),
                        onLongPress: () {
                          ref
                              .read(isSelectionModeProvider.notifier)
                              .state = true;
                          ref
                              .read(selectedDocumentIdsProvider.notifier)
                              .state = {doc.id};
                        },
                        onSelectChanged: (val) {
                          final current = Set<int>.from(selectedIds);
                          if (val == true) {
                            current.add(doc.id);
                          } else {
                            current.remove(doc.id);
                          }
                          ref
                              .read(selectedDocumentIdsProvider.notifier)
                              .state = current;
                        },
                        onFavoriteToggle: () {
                          ref
                              .read(filesControllerProvider.notifier)
                              .toggleFavorite(doc);
                        },
                        onMorePressed: () => _showDocumentActions(doc),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
