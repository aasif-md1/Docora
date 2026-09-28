import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet allowing customization of EPUB reader options:
/// font size scale and reading comfort mode (Normal, Dark, Sepia).
class EpubFontSizeSheet extends StatelessWidget {
  const EpubFontSizeSheet({
    required this.currentFontSize,
    required this.onFontSizeChanged,
    required this.currentReadingMode,
    required this.onReadingModeChanged,
    super.key,
  });

  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;
  final PdfReadingMode currentReadingMode;
  final ValueChanged<PdfReadingMode> onReadingModeChanged;

  static const List<double> _fontSizes = [12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(LucideIcons.type, size: 22, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Reading Display Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Theme & Eye Comfort',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  context,
                  title: 'Default',
                  mode: PdfReadingMode.normal,
                  bg: colorScheme.surfaceContainerHighest,
                  fg: colorScheme.onSurface,
                  icon: LucideIcons.sun,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  context,
                  title: 'Sepia',
                  mode: PdfReadingMode.sepia,
                  bg: const Color(0xFFFBF0D9),
                  fg: const Color(0xFF5F4B32),
                  icon: LucideIcons.book_open,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  context,
                  title: 'Dark',
                  mode: PdfReadingMode.dark,
                  bg: const Color(0xFF1E1E1E),
                  fg: const Color(0xFFE0E0E0),
                  icon: LucideIcons.moon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Font Size',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${currentFontSize.toInt()} pt',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _fontSizes.map((size) {
                final isSelected = (size - currentFontSize).abs() < 0.5;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${size.toInt()}'),
                    selected: isSelected,
                    onSelected: (_) => onFontSizeChanged(size),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Preview container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              'The quick brown fox jumps over the lazy dog.',
              style: TextStyle(
                fontSize: currentFontSize,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required PdfReadingMode mode,
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentReadingMode == mode;

    return InkWell(
      onTap: () => onReadingModeChanged(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
