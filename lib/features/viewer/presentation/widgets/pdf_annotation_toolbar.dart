import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/features/viewer/domain/models/pdf_annotation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PdfAnnotationToolbar extends StatelessWidget {
  const PdfAnnotationToolbar({
    required this.activeTool,
    required this.activeColor,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onUndo,
    required this.onClearPage,
    required this.onAddSignature,
    required this.onClose,
    super.key,
  });

  final AnnotationTool activeTool;
  final Color activeColor;
  final ValueChanged<AnnotationTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onUndo;
  final VoidCallback onClearPage;
  final VoidCallback onAddSignature;
  final VoidCallback onClose;

  static const List<Color> palette = [
    Color(0xFFEAB308), // Highlighter Gold
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFEF4444), // Crimson
    Color(0xFF8B5CF6), // Violet
    Color(0xFF1F2937), // Dark Charcoal
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      color: colorScheme.surfaceContainerHigh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pen tool
            _ToolItem(
              icon: LucideIcons.pencil,
              label: 'Pen',
              isSelected: activeTool == AnnotationTool.pen,
              onTap: () {
                AppMotion.subtleHaptic();
                onToolChanged(activeTool == AnnotationTool.pen
                    ? AnnotationTool.none
                    : AnnotationTool.pen);
              },
            ),

            // Highlighter tool
            _ToolItem(
              icon: LucideIcons.highlighter,
              label: 'Highlight',
              isSelected: activeTool == AnnotationTool.highlighter,
              onTap: () {
                AppMotion.subtleHaptic();
                onToolChanged(activeTool == AnnotationTool.highlighter
                    ? AnnotationTool.none
                    : AnnotationTool.highlighter);
              },
            ),

            // Text Note pin
            _ToolItem(
              icon: LucideIcons.sticky_note,
              label: 'Note',
              isSelected: activeTool == AnnotationTool.note,
              onTap: () {
                AppMotion.subtleHaptic();
                onToolChanged(activeTool == AnnotationTool.note
                    ? AnnotationTool.none
                    : AnnotationTool.note);
              },
            ),

            // Signature tool
            _ToolItem(
              icon: LucideIcons.signature,
              label: 'Sign',
              isSelected: activeTool == AnnotationTool.signature,
              onTap: () {
                AppMotion.subtleHaptic();
                onAddSignature();
              },
            ),

            // Eraser
            _ToolItem(
              icon: LucideIcons.eraser,
              label: 'Eraser',
              isSelected: activeTool == AnnotationTool.eraser,
              onTap: () {
                AppMotion.subtleHaptic();
                onToolChanged(activeTool == AnnotationTool.eraser
                    ? AnnotationTool.none
                    : AnnotationTool.eraser);
              },
            ),

            Container(
              height: 24,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: colorScheme.outlineVariant,
            ),

            // Color Selector (tap cycle)
            GestureDetector(
              onTap: () {
                AppMotion.subtleHaptic();
                final nextIdx = (palette.indexOf(activeColor) + 1) % palette.length;
                onColorChanged(palette[nextIdx]);
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withAlpha(120),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Undo
            IconButton(
              icon: const Icon(LucideIcons.undo_2, size: 18),
              tooltip: 'Undo',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                AppMotion.subtleHaptic();
                onUndo();
              },
            ),

            // Close
            IconButton(
              icon: const Icon(LucideIcons.check, size: 18, color: AppColors.success500),
              tooltip: 'Done',
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
