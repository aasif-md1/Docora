import 'package:docora/features/viewer/domain/models/epub_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet displaying EPUB Table of Contents.
class EpubTocSheet extends StatelessWidget {
  const EpubTocSheet({
    required this.tocEntries,
    required this.currentChapterIndex,
    required this.onChapterSelected,
    super.key,
  });

  final List<EpubTocEntry> tocEntries;
  final int currentChapterIndex;
  final ValueChanged<int> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(LucideIcons.book_open, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Table of Contents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tocEntries.length} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (tocEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.list_x, size: 36, color: colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      'No table of contents available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: tocEntries.length,
                itemBuilder: (context, index) {
                  final entry = tocEntries[index];
                  return _buildTocEntryTile(context, entry, depth: 0);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTocEntryTile(BuildContext context, EpubTocEntry entry, {required int depth}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = entry.targetChapterIndex == currentChapterIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.only(
              left: 20.0 + (depth * 16.0),
              right: 20.0,
            ),
            leading: Icon(
              isSelected ? LucideIcons.circle_check : LucideIcons.circle,
              size: isSelected ? 18 : 10,
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
            title: Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            trailing: Text(
              'Ch ${entry.targetChapterIndex + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
            ),
            selected: isSelected,
            onTap: () {
              Navigator.pop(context);
              onChapterSelected(entry.targetChapterIndex);
            },
          ),
        ),
        for (final child in entry.children)
          _buildTocEntryTile(context, child, depth: depth + 1),
      ],
    );
  }
}
