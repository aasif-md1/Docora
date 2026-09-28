import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Floating search bar for full-text search in Word document viewer.
class DocxSearchBarWidget extends StatefulWidget {
  const DocxSearchBarWidget({
    required this.totalMatches,
    required this.currentMatchIndex,
    required this.onSearchChanged,
    required this.onNextMatch,
    required this.onPrevMatch,
    required this.onClose,
    super.key,
  });

  final int totalMatches;
  final int currentMatchIndex;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNextMatch;
  final VoidCallback onPrevMatch;
  final VoidCallback onClose;

  @override
  State<DocxSearchBarWidget> createState() => _DocxSearchBarWidgetState();
}

class _DocxSearchBarWidgetState extends State<DocxSearchBarWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String matchText = '';
    if (widget.totalMatches > 0) {
      matchText = '${widget.currentMatchIndex + 1} of ${widget.totalMatches}';
    } else if (_textController.text.trim().isNotEmpty) {
      matchText = '0 of 0';
    }

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Search in Word document...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
                style: theme.textTheme.bodyMedium,
                onChanged: widget.onSearchChanged,
                onSubmitted: (_) {
                  if (widget.totalMatches > 0) {
                    widget.onNextMatch();
                  }
                },
              ),
            ),
            if (matchText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  matchText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(LucideIcons.chevron_up, size: 20),
              tooltip: 'Previous match',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: widget.totalMatches > 0 ? widget.onPrevMatch : null,
            ),
            IconButton(
              icon: const Icon(LucideIcons.chevron_down, size: 20),
              tooltip: 'Next match',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: widget.totalMatches > 0 ? widget.onNextMatch : null,
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 20),
              tooltip: 'Close search',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}
