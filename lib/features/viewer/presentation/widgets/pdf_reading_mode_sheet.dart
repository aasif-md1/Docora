import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet allowing selection of eye-comfort and night reading modes.
class PdfReadingModeSheet extends StatelessWidget {
  const PdfReadingModeSheet({
    required this.currentMode,
    required this.onModeSelected,
    super.key,
  });

  final PdfReadingMode currentMode;
  final ValueChanged<PdfReadingMode> onModeSelected;

  static void show({
    required BuildContext context,
    required PdfReadingMode currentMode,
    required ValueChanged<PdfReadingMode> onModeSelected,
  }) {
    DocoraBottomSheet.show<void>(
      context: context,
      title: 'Reading Mode',
      subtitle: 'Adjust color rendering for reading comfort',
      showCloseButton: true,
      builder: (_) => PdfReadingModeSheet(
        currentMode: currentMode,
        onModeSelected: onModeSelected,
      ),
    );
  }

  IconData _iconForMode(PdfReadingMode mode) {
    switch (mode) {
      case PdfReadingMode.normal:
        return LucideIcons.sun;
      case PdfReadingMode.dark:
        return LucideIcons.moon;
      case PdfReadingMode.sepia:
        return LucideIcons.coffee;
      case PdfReadingMode.grayscale:
        return LucideIcons.contrast;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: PdfReadingMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return DocoraActionTile(
            icon: _iconForMode(mode),
            title: mode.label,
            subtitle: mode.description,
            trailing: isSelected
                ? Icon(
                    LucideIcons.check,
                    color: colorScheme.primary,
                    size: 20,
                  )
                : null,
            onTap: () {
              Navigator.of(context).pop();
              onModeSelected(mode);
            },
          );
        }).toList(),
      ),
    );
  }
}
