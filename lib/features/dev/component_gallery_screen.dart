import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/app_theme.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Developer Component Gallery for testing and validating all Docora tokens and UI components.
/// Allows live testing of Light, Dark, AMOLED themes, accent colors, and component states.
class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() =>
      _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState
    extends ConsumerState<ComponentGalleryScreen> {
  String _selectedFilter = 'all';
  bool _isLoadingButtons = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  final List<DocumentEntity> _sampleDocs = [
    DocumentEntity(
      id: 1,
      path: '/storage/emulated/0/Documents/Annual_Report_2026.pdf',
      name: 'Annual_Report_2026.pdf',
      extension: 'pdf',
      mimeType: 'application/pdf',
      sizeBytes: 4850000,
      lastModified: DateTime.now().subtract(const Duration(hours: 3)),
      openCount: 14,
      isFavorite: true,
      isDeleted: false,
      tags: const ['Finance', 'Q4'],
      category: 'pdf',
      pageCount: 42,
    ),
    DocumentEntity(
      id: 2,
      path: '/storage/emulated/0/Documents/Architecture_Proposal.docx',
      name: 'Architecture_Proposal.docx',
      extension: 'docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      sizeBytes: 1250000,
      lastModified: DateTime.now().subtract(const Duration(days: 1)),
      openCount: 8,
      isFavorite: false,
      isDeleted: false,
      tags: const ['Engineering'],
      category: 'word',
      pageCount: 12,
    ),
    DocumentEntity(
      id: 3,
      path: '/storage/emulated/0/Downloads/Q3_Budget_Forecast.xlsx',
      name: 'Q3_Budget_Forecast.xlsx',
      extension: 'xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      sizeBytes: 890000,
      lastModified: DateTime.now().subtract(const Duration(days: 4)),
      openCount: 3,
      isFavorite: true,
      isDeleted: false,
      tags: const ['Spreadsheet'],
      category: 'excel',
      pageCount: 5,
    ),
    DocumentEntity(
      id: 4,
      path: '/storage/emulated/0/Documents/Keynote_Deck.pptx',
      name: 'Keynote_Deck.pptx',
      extension: 'pptx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      sizeBytes: 15400000,
      lastModified: DateTime.now().subtract(const Duration(days: 7)),
      openCount: 2,
      isFavorite: false,
      isDeleted: false,
      tags: const ['Presentation'],
      category: 'ppt',
      pageCount: 28,
    ),
  ];

  void _showSampleActionSheet(DocumentEntity doc) {
    DocoraBottomSheet.show<void>(
      context: context,
      title: doc.name,
      subtitle: '${doc.formattedSize} • ${doc.extension.toUpperCase()}',
      showCloseButton: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DocoraActionTile(
            icon: LucideIcons.share_2,
            title: 'Share File',
            subtitle: 'Send via system share sheet',
            onTap: () => Navigator.pop(ctx),
          ),
          DocoraActionTile(
            icon: LucideIcons.pencil,
            title: 'Rename',
            onTap: () => Navigator.pop(ctx),
          ),
          DocoraActionTile(
            icon: LucideIcons.bookmark,
            title: doc.isFavorite ? 'Remove Favorite' : 'Add to Favorites',
            onTap: () => Navigator.pop(ctx),
          ),
          DocoraActionTile(
            icon: LucideIcons.info,
            title: 'File Details',
            onTap: () => Navigator.pop(ctx),
          ),
          const Divider(height: 1),
          DocoraActionTile(
            icon: LucideIcons.trash,
            title: 'Move to Trash',
            isDestructive: true,
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentThemeMode = ref.watch(themeModeProvider);
    final isAmoled = ref.watch(isAmoledProvider);
    final selectedAccentIdx = ref.watch(accentColorIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Docora Component Gallery'),
        actions: [
          IconButton(
            icon: Icon(
              _isSelectionMode
                  ? LucideIcons.square_check
                  : LucideIcons.square,
            ),
            tooltip: 'Toggle Selection Mode',
            onPressed: () {
              AppMotion.subtleHaptic();
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedIds.clear();
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
        children: [
          // Section: Theme & Appearance Controls
          _buildSectionHeader('Theme & Appearance Controls'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DocoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(LucideIcons.sun, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(LucideIcons.moon, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(LucideIcons.monitor, size: 16),
                      ),
                    ],
                    selected: {currentThemeMode},
                    onSelectionChanged: (modes) {
                      AppMotion.subtleHaptic();
                      ref.read(themeModeProvider.notifier).setThemeMode(modes.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('AMOLED Pure Black'),
                    subtitle:
                        const Text('True #000000 background for OLED screens'),
                    value: isAmoled,
                    onChanged: (val) {
                      AppMotion.subtleHaptic();
                      ref.read(isAmoledProvider.notifier).setAmoled(val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Accent Color',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      AppColors.accentOptions.length,
                      (idx) {
                        final color = AppColors.accentOptions[idx];
                        final isSelected = selectedAccentIdx == idx;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            AppMotion.subtleHaptic();
                            ref
                                .read(accentColorIndexProvider.notifier)
                                .setAccentIndex(idx);
                          },
                          child: AnimatedContainer(
                            duration: AppMotion.shortDuration,
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    LucideIcons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section: Format Badges
          _buildSectionHeader('Format Badges (Zero Emoji)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const DocumentFormatBadge(
                  format: DocumentFormat.pdf,
                  size: BadgeSize.large,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.word,
                  size: BadgeSize.large,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.excel,
                  size: BadgeSize.large,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.ppt,
                  size: BadgeSize.large,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.image,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.code,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.archive,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.epub,
                  size: BadgeSize.small,
                ),
                const DocumentFormatBadge(
                  format: DocumentFormat.text,
                  size: BadgeSize.small,
                ),
              ],
            ),
          ),

          // Section: Docora Buttons
          _buildSectionHeader('Docora Buttons & Loading States'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DocoraButton(
                        label: 'Primary Button',
                        icon: LucideIcons.sparkles,
                        isLoading: _isLoadingButtons,
                        onPressed: () {
                          setState(() => _isLoadingButtons = true);
                          Future.delayed(
                            const Duration(seconds: 2),
                            () => setState(() => _isLoadingButtons = false),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DocoraButton(
                        label: 'Secondary',
                        variant: DocoraButtonVariant.secondary,
                        icon: LucideIcons.sliders_horizontal,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DocoraButton(
                        label: 'Outlined',
                        variant: DocoraButtonVariant.outlined,
                        icon: LucideIcons.download,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DocoraButton(
                        label: 'Ghost',
                        variant: DocoraButtonVariant.ghost,
                        icon: LucideIcons.eye,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Section: Search Field & Filter Chips
          _buildSectionHeader('Search Bar & Filter Chip Bar'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DocoraSearchField(
              hintText: 'Search documents, tags, or content...',
              onFilterTap: () {
                _showSampleActionSheet(_sampleDocs.first);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilterChipBar(
            selectedId: _selectedFilter,
            onSelected: (id) => setState(() => _selectedFilter = id),
          ),

          // Section: Cards Demo
          _buildSectionHeader('Docora Cards (Elevated, Filled, Outlined)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: DocoraCard(
                    variant: DocoraCardVariant.elevated,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.file_text, size: 20),
                        const SizedBox(height: 6),
                        Text(
                          'Elevated',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DocoraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.shield, size: 20),
                        const SizedBox(height: 6),
                        Text(
                          'Filled',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DocoraCard(
                    variant: DocoraCardVariant.outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.layers, size: 20),
                        const SizedBox(height: 6),
                        Text(
                          'Outlined',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section: Document List Items
          _buildSectionHeader('Document List Items'),
          ..._sampleDocs.map(
            (doc) => DocumentListItem(
              document: doc,
              isSelected: _selectedIds.contains(doc.id),
              isSelectionMode: _isSelectionMode,
              readingProgress: doc.category == 'pdf' ? 0.65 : null,
              onSelectChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedIds.add(doc.id);
                  } else {
                    _selectedIds.remove(doc.id);
                  }
                });
              },
              onMorePressed: () => _showSampleActionSheet(doc),
              onFavoriteToggle: () {
                final idx = _sampleDocs.indexWhere((d) => d.id == doc.id);
                setState(() {
                  _sampleDocs[idx] =
                      doc.copyWith(isFavorite: !doc.isFavorite);
                });
              },
            ),
          ),

          // Section: Document Grid Items
          _buildSectionHeader('Document Grid Items (2-Column Grid)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: 2,
              itemBuilder: (context, index) {
                final doc = _sampleDocs[index];
                return DocumentGridItem(
                  document: doc,
                  readingProgress: doc.category == 'pdf' ? 0.65 : null,
                  onMorePressed: () => _showSampleActionSheet(doc),
                  onFavoriteToggle: () {
                    setState(() {
                      _sampleDocs[index] =
                          doc.copyWith(isFavorite: !doc.isFavorite);
                    });
                  },
                );
              },
            ),
          ),

          // Section: Shimmer Skeleton Loaders
          _buildSectionHeader('Shimmer Skeleton Loader'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                DocumentListItemSkeleton(),
                SizedBox(height: AppSpacing.sm),
                DocumentListItemSkeleton(),
              ],
            ),
          ),

          // Section: Empty State
          _buildSectionHeader('Docora Empty State'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DocoraCard(
              variant: DocoraCardVariant.outlined,
              child: DocoraEmptyState(
                icon: LucideIcons.folder_search,
                title: 'No Documents Found',
                description:
                    'Drop documents into your device or tap scan to import your first file.',
                actionLabel: 'Scan Document',
                actionIcon: LucideIcons.scan_line,
                onAction: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
