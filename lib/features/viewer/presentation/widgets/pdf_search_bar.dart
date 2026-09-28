import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pdfrx/pdfrx.dart';

/// Floating in-document search bar overlay for the PDF viewer.
/// Controls a [PdfTextSearcher] to highlight text and navigate between matches.
class PdfSearchBarWidget extends StatefulWidget {
  const PdfSearchBarWidget({
    required this.searcher,
    required this.onClose,
    super.key,
  });

  final PdfTextSearcher searcher;
  final VoidCallback onClose;

  @override
  State<PdfSearchBarWidget> createState() => _PdfSearchBarWidgetState();
}

class _PdfSearchBarWidgetState extends State<PdfSearchBarWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.searcher.addListener(_onSearchChanged);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    widget.searcher.removeListener(_onSearchChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      widget.searcher.resetTextSearch();
    } else {
      widget.searcher.startTextSearch(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searcher = widget.searcher;

    final matchCount = searcher.matches.length;
    final currentIdx = searcher.currentIndex;

    String matchText = '';
    if (_textController.text.trim().isNotEmpty) {
      if (matchCount == 0) {
        matchText = '0 of 0';
      } else if (currentIdx != null) {
        matchText = '${currentIdx + 1} of $matchCount';
      } else {
        matchText = '$matchCount found';
      }
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
                  hintText: 'Search in document...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
                style: theme.textTheme.bodyMedium,
                onChanged: _performSearch,
                onSubmitted: (_) {
                  if (matchCount > 0) {
                    searcher.goToNextMatch();
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
              onPressed: matchCount > 0 ? searcher.goToPrevMatch : null,
            ),
            IconButton(
              icon: const Icon(LucideIcons.chevron_down, size: 20),
              tooltip: 'Next match',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: matchCount > 0 ? searcher.goToNextMatch : null,
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 20),
              tooltip: 'Close search',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                searcher.resetTextSearch();
                widget.onClose();
              },
            ),
          ],
        ),
      ),
    );
  }
}
