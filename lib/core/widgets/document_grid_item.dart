import 'dart:io';

import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/document_format_badge.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

/// Premium Document Grid Item component for grid/card layouts.
/// Displays document thumbnail/icon hero, format badge, favorite toggle, and metadata.
class DocumentGridItem extends StatelessWidget {
  const DocumentGridItem({
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

  String _formatDate(DateTime dt) => DateFormat.MMMd().format(dt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final format = DocumentFormat.fromExtension(document.extension);
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;

    final hasThumbnail = document.thumbnailPath != null &&
        File(document.thumbnailPath!).existsSync();

    return Semantics(
      label: '${document.name}, ${format.label}, ${document.formattedSize}',
      selected: isSelected,
      button: true,
      child: DecoratedBox(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Preview Area
                Expanded(
                  child: Stack(
                    children: [
                      // Preview content or colored format canvas
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: format.color.withAlpha(20),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.radiusLg - 1),
                          ),
                        ),
                        child: Center(
                          child: hasThumbnail
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(
                                      AppSpacing.radiusLg - 1,
                                    ),
                                  ),
                                  child: Image.file(
                                    File(document.thumbnailPath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )
                              : Icon(
                                  format.icon,
                                  size: 44,
                                  color: format.color,
                                ),
                        ),
                      ),

                      // Top-Left Format Badge
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: DocumentFormatBadge(
                          format: format,
                          size: BadgeSize.small,
                        ),
                      ),

                      // Top-Right Favorite or Selection Check
                      Positioned(
                        top: 2,
                        right: 2,
                        child: isSelectionMode
                            ? Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: AnimatedContainer(
                                  duration: AppMotion.shortDuration,
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.black38,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : Colors.white70,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          LucideIcons.check,
                                          size: 13,
                                          color: colorScheme.onPrimary,
                                        )
                                      : null,
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  document.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 18,
                                  color: document.isFavorite
                                      ? const Color(0xFFF59E0B)
                                      : Colors.grey.shade600,
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  AppMotion.subtleHaptic();
                                  onFavoriteToggle?.call();
                                },
                              ),
                      ),

                      // Reading Progress Track at bottom of preview
                      if (readingProgress != null && readingProgress! > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: readingProgress!.clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              format.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bottom Details
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        document.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            document.formattedSize,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(document.lastModified),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
