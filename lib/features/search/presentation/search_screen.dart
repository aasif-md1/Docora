import 'dart:async';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search-local query state — separate from the global files screen query
final _searchLocalQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Search-local category filter
final _searchCategoryProvider = StateProvider.autoDispose<String>((ref) => 'all');

/// Search results: reuses the existing watchDocuments with the local query
final _searchResultsStreamProvider =
    StreamProvider.autoDispose<List<DocumentEntity>>((ref) {
  final query = ref.watch(_searchLocalQueryProvider);
  final category = ref.watch(_searchCategoryProvider);
  final repo = ref.watch(documentRepositoryProvider);

  if (query.trim().isEmpty) return Stream.value([]);

  return repo.watchDocuments(
    category: category == 'all' ? null : category,
    query: query,
  );
});

/// Global search screen — fully functional real-time filename search with
/// filter chips and animated results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  static const List<_QuickFilter> _filters = [
    _QuickFilter('all', 'All', LucideIcons.layers),
    _QuickFilter('pdf', 'PDF', LucideIcons.file_text),
    _QuickFilter('word', 'Word', LucideIcons.file_pen),
    _QuickFilter('excel', 'Excel', LucideIcons.file_spreadsheet),
    _QuickFilter('ppt', 'PPT', LucideIcons.file_play),
    _QuickFilter('image', 'Image', LucideIcons.image),
    _QuickFilter('text', 'Text', LucideIcons.file_code),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(_searchLocalQueryProvider.notifier).state = value.trim();
      }
    });
  }

  void _quickSearch(String term) {
    AppMotion.subtleHaptic();
    _controller.text = term;
    _controller.selection =
        TextSelection.collapsed(offset: term.length);
    ref.read(_searchLocalQueryProvider.notifier).state = term;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = ref.watch(_searchLocalQueryProvider);
    final selectedCategory = ref.watch(_searchCategoryProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(LucideIcons.arrow_left),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search by filename, extension...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(130),
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _controller.clear();
                              ref.read(_searchLocalQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _filters[index];
                final selected = selectedCategory == f.id;
                return FilterChip(
                  avatar: Icon(f.icon, size: 14),
                  label: Text(f.label),
                  selected: selected,
                  onSelected: (_) {
                    AppMotion.subtleHaptic();
                    ref.read(_searchCategoryProvider.notifier).state = f.id;
                  },
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Results
          Expanded(
            child: query.isEmpty
                ? _buildEmptyHint(theme, colorScheme)
                : _buildSearchResults(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHint(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
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
                LucideIcons.search,
                size: 36,
                color: colorScheme.primary.withAlpha(140),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Search Your Documents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Type a filename, extension, or keyword to search\nacross all indexed documents on your device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: '.pdf',
                  onTap: () => _quickSearch('.pdf'),
                ),
                _SuggestionChip(
                  label: '.docx',
                  onTap: () => _quickSearch('.docx'),
                ),
                _SuggestionChip(
                  label: 'invoice',
                  onTap: () => _quickSearch('invoice'),
                ),
                _SuggestionChip(
                  label: 'report',
                  onTap: () => _quickSearch('report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, ColorScheme colorScheme) {
    final query = ref.watch(_searchLocalQueryProvider);
    final resultsAsync = ref.watch(_searchResultsStreamProvider);

    return resultsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: 6,
        itemBuilder: (_, __) => const DocumentListItemSkeleton(),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.triangle_alert,
                size: 48, color: colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Search failed: $err',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.search_x,
                    size: 32,
                    color: colorScheme.error.withAlpha(180),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Results Found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'No documents matching "$query"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                '${results.length} result${results.length == 1 ? '' : 's'} for "$query"',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final doc = results[index];
                  return DocumentListItem(
                    document: doc,
                    onTap: () {
                      AppMotion.subtleHaptic();
                      ref.read(filesControllerProvider.notifier).markOpened(doc);
                      DocumentOpener.open(context, doc.path);
                    },
                    onFavoriteToggle: () {
                      ref.read(filesControllerProvider.notifier).toggleFavorite(doc);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickFilter {
  const _QuickFilter(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(LucideIcons.sparkles, size: 14, color: colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
    );
  }
}
