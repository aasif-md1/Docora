import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet allowing customization of text viewer display options:
/// font size, line numbers gutter, and word wrapping.
class TextFontSizeSheet extends StatelessWidget {
  const TextFontSizeSheet({
    required this.currentFontSize,
    required this.onFontSizeChanged,
    required this.showLineNumbers,
    required this.onToggleLineNumbers,
    required this.wrapLines,
    required this.onToggleWrapLines,
    super.key,
  });

  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;
  final bool showLineNumbers;
  final VoidCallback onToggleLineNumbers;
  final bool wrapLines;
  final VoidCallback onToggleWrapLines;

  static const List<double> _fontSizes = [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
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
              Icon(
                LucideIcons.settings_2,
                size: 22,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'View & Typography Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Font Size Selector
          Text(
            'Font Size',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _fontSizes.map((size) {
                final isSelected = (currentFontSize - size).abs() < 0.5;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${size.toInt()} pt'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) onFontSizeChanged(size);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          // Toggle Line Numbers
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              LucideIcons.list_ordered,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            title: const Text('Show Line Numbers'),
            subtitle: const Text('Display numbered gutter on left edge'),
            value: showLineNumbers,
            onChanged: (_) => onToggleLineNumbers(),
          ),

          // Toggle Word Wrap
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              LucideIcons.text_wrap,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            title: const Text('Wrap Long Lines'),
            subtitle: const Text('Wrap text to screen width or scroll horizontally'),
            value: wrapLines,
            onChanged: (_) => onToggleWrapLines(),
          ),
        ],
      ),
    );
  }
}
