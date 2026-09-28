import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet for adjusting text scaling dynamically without re-parsing.
class DocxFontScaleSheet extends StatelessWidget {
  const DocxFontScaleSheet({
    required this.currentScale,
    required this.onScaleChanged,
    super.key,
  });

  final double currentScale;
  final ValueChanged<double> onScaleChanged;

  static void show({
    required BuildContext context,
    required double currentScale,
    required ValueChanged<double> onScaleChanged,
  }) {
    DocoraBottomSheet.show<void>(
      context: context,
      title: 'Text Size',
      subtitle: 'Scale text size from 80% to 200%',
      showCloseButton: true,
      builder: (_) => DocxFontScaleSheet(
        currentScale: currentScale,
        onScaleChanged: onScaleChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = (currentScale * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Scaling',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(LucideIcons.type, size: 16),
              Expanded(
                child: Slider(
                  value: currentScale,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  onChanged: onScaleChanged,
                ),
              ),
              const Icon(LucideIcons.type, size: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [0.8, 1.0, 1.25, 1.5, 2.0].map((scale) {
              final isSelected = (currentScale - scale).abs() < 0.05;
              return ChoiceChip(
                label: Text('${(scale * 100).round()}%'),
                selected: isSelected,
                onSelected: (_) => onScaleChanged(scale),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
