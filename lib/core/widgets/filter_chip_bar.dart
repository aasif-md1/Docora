import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Item descriptor for [FilterChipBar].
class FilterChipItem {
  const FilterChipItem({
    required this.id,
    required this.label,
    this.icon,
    this.format,
    this.count,
  });

  final String id;
  final String label;
  final IconData? icon;
  final DocumentFormat? format;
  final int? count;

  /// Default list of category filters for Docora
  static List<FilterChipItem> get defaultFilters => [
        const FilterChipItem(
          id: 'all',
          label: 'All',
          icon: LucideIcons.layout_grid,
        ),
        FilterChipItem(
          id: 'pdf',
          label: 'PDF',
          format: DocumentFormat.pdf,
          icon: DocumentFormat.pdf.icon,
        ),
        FilterChipItem(
          id: 'word',
          label: 'Word',
          format: DocumentFormat.word,
          icon: DocumentFormat.word.icon,
        ),
        FilterChipItem(
          id: 'excel',
          label: 'Excel',
          format: DocumentFormat.excel,
          icon: DocumentFormat.excel.icon,
        ),
        FilterChipItem(
          id: 'ppt',
          label: 'PPT',
          format: DocumentFormat.ppt,
          icon: DocumentFormat.ppt.icon,
        ),
        FilterChipItem(
          id: 'image',
          label: 'Images',
          format: DocumentFormat.image,
          icon: DocumentFormat.image.icon,
        ),
        FilterChipItem(
          id: 'text',
          label: 'Text',
          format: DocumentFormat.text,
          icon: DocumentFormat.text.icon,
        ),
        FilterChipItem(
          id: 'code',
          label: 'Code',
          format: DocumentFormat.code,
          icon: DocumentFormat.code.icon,
        ),
        FilterChipItem(
          id: 'archive',
          label: 'Archives',
          format: DocumentFormat.archive,
          icon: DocumentFormat.archive.icon,
        ),
      ];
}

/// A horizontally scrollable filter chip bar for format and category filtering.
/// Styled according to Docora design tokens with smooth haptics and animations.
class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    required this.selectedId,
    required this.onSelected,
    super.key,
    this.items,
    this.padding,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;
  final List<FilterChipItem>? items;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;
    final filterList = items ?? FilterChipItem.defaultFilters;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: filterList.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = filterList[index];
          final isSelected = item.id.toLowerCase() == selectedId.toLowerCase();

          final activeColor = item.format?.color ?? colorScheme.primary;

          return Semantics(
            button: true,
            selected: isSelected,
            label: '${item.label} filter',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                onTap: () {
                  AppMotion.subtleHaptic();
                  onSelected(item.id);
                },
                child: AnimatedContainer(
                  duration: AppMotion.shortDuration,
                  curve: AppMotion.standardDecel,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withAlpha(28)
                        : isAmoled
                            ? const Color(0xFF141414)
                            : colorScheme.surfaceContainerHigh.withAlpha(120),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : isAmoled
                              ? const Color(0xFF262626)
                              : colorScheme.outlineVariant.withAlpha(60),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: 14,
                          color: isSelected
                              ? activeColor
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? activeColor
                              : colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      if (item.count != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor.withAlpha(40)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.count}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: isSelected
                                  ? activeColor
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
