import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/features/viewer/domain/models/spreadsheet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Pinned formula bar at top of spreadsheet viewer showing active cell coordinate,
/// data type indicator, and formula or raw value.
class SpreadsheetFormulaBar extends StatelessWidget {
  const SpreadsheetFormulaBar({
    required this.selectedCell,
    super.key,
  });

  final SpreadsheetCell? selectedCell;

  IconData _iconForType(SpreadsheetCellType type) {
    switch (type) {
      case SpreadsheetCellType.number:
        return LucideIcons.hash;
      case SpreadsheetCellType.date:
        return LucideIcons.calendar;
      case SpreadsheetCellType.boolean:
        return LucideIcons.square_check;
      case SpreadsheetCellType.formula:
        return LucideIcons.variable;
      case SpreadsheetCellType.text:
      case SpreadsheetCellType.empty:
        return LucideIcons.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cell = selectedCell;

    final coordinate = cell != null ? cell.coordinate : '—';
    final displayText = cell != null
        ? (cell.formula != null ? cell.formula! : cell.value)
        : 'Select a cell to inspect value';
    final typeIcon = cell != null ? _iconForType(cell.type) : LucideIcons.mouse_pointer_click;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(120),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(100),
          ),
        ),
      ),
      child: Row(
        children: [
          // Cell Coordinate Badge (e.g., "B4")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(140),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: colorScheme.primary.withAlpha(80),
              ),
            ),
            child: Text(
              coordinate,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Type Icon
          Icon(
            typeIcon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Value / Formula text
          Expanded(
            child: Text(
              displayText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: cell?.formula != null ? 'monospace' : null,
                color: cell != null
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withAlpha(140),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Copy button
          if (cell != null && cell.value.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.copy, size: 16),
              tooltip: 'Copy cell value',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: cell.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied ${cell.coordinate} value to clipboard'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
