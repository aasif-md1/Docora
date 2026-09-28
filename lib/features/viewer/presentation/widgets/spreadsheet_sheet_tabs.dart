import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Bottom tab switcher for multi-sheet workbooks.
class SpreadsheetSheetTabs extends StatelessWidget {
  const SpreadsheetSheetTabs({
    required this.sheetNames,
    required this.currentIndex,
    required this.onSheetSelected,
    super.key,
  });

  final List<String> sheetNames;
  final int currentIndex;
  final ValueChanged<int> onSheetSelected;

  @override
  Widget build(BuildContext context) {
    if (sheetNames.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              LucideIcons.sheet,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              itemCount: sheetNames.length,
              separatorBuilder: (context, index) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final isSelected = index == currentIndex;
                final name = sheetNames[index];

                return InkWell(
                  onTap: () => onSheetSelected(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.secondaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: colorScheme.primary,
                              width: 1.2,
                            )
                          : Border.all(
                              color: colorScheme.outlineVariant.withAlpha(50),
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(
                            LucideIcons.table,
                            size: 14,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
