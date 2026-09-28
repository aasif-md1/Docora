import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/document_format_badge.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

/// Premium Document List Item component with zero emojis.
/// Supports reading progress, selection mode, favorites, and action overflow.
class DocumentListItem extends StatelessWidget {
  const DocumentListItem({
    required this.document,
    super.key,
    this.onTap,
    this.onLongPress,
    this.onMorePressed,
    this.onFavoriteToggle,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectChanged,
    this.readingProgress,
  });

  final DocumentEntity document;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMorePressed;
  final VoidCallback? onFavoriteToggle;
  final bool isSelected;
  final bool isSelectionMode;
  final ValueChanged<bool?>? onSelectChanged;
  final double? readingProgress;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return DateFormat.jm().format(dt);
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(dt);
    } else if (dt.year == now.year) {
      return DateFormat.MMMd().format(dt);
    }
    return DateFormat.yMMMd().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final format = DocumentFormat.fromExtension(document.extension);
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;

    final progress = readingProgress;

    return Semantics(
      label: '${document.name}, ${format.label}, ${document.formattedSize}',
      selected: isSelected,
      button: true,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(80)
              : isAmoled
                  ? const Color(0xFF0F0F0F)
                  : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : isAmoled
                    ? const Color(0xFF222222)
                    : colorScheme.outlineVariant.withAlpha(60),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: () {
              AppMotion.subtleHaptic();
              if (isSelectionMode) {
                onSelectChanged?.call(!isSelected);
              } else {
                onTap?.call();
              }
            },
            onLongPress: () {
              AppMotion.subtleHaptic();
              onLongPress?.call();
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Selection Checkbox or Format Badge
                  if (isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: AnimatedContainer(
                        duration: AppMotion.shortDuration,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                LucideIcons.check,
                                size: 14,
                                color: colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ),

                  // Format Badge
                  DocumentFormatBadge(
                    format: format,
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              document.formattedSize,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: colorScheme.outlineVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(document.lastModified),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (document.pageCount != null &&
                                document.pageCount! > 0) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: colorScheme.outlineVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Text(
                                '${document.pageCount} pgs',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (progress != null && progress > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    minHeight: 4,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      format.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: format.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions: Favorite and More
                  if (!isSelectionMode) ...[
                    IconButton(
                      icon: Icon(
                        document.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 20,
                        color: document.isFavorite
                            ? const Color(0xFFF59E0B)
                            : colorScheme.onSurfaceVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: document.isFavorite
                          ? 'Remove favorite'
                          : 'Mark favorite',
                      onPressed: () {
                        AppMotion.subtleHaptic();
                        onFavoriteToggle?.call();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.ellipsis_vertical,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'More actions',
                      onPressed: () {
                        AppMotion.subtleHaptic();
                        onMorePressed?.call();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
