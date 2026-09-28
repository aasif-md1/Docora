import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Top in-document search bar for finding text within files.
class TextSearchBar extends StatefulWidget {
  const TextSearchBar({
    required this.totalMatches,
    required this.currentMatchIndex,
    required this.onQueryChanged,
    required this.onPreviousMatch,
    required this.onNextMatch,
    required this.onClose,
    super.key,
  });

  final int totalMatches;
  final int currentMatchIndex;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onPreviousMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onClose;

  @override
  State<TextSearchBar> createState() => _TextSearchBarState();
}

class _TextSearchBarState extends State<TextSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.search,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (val) {
                setState(() {});
                widget.onQueryChanged(val);
              },
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search in file...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty) ...[
            Text(
              widget.totalMatches > 0
                  ? '${widget.currentMatchIndex + 1} of ${widget.totalMatches}'
                  : '0 found',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(LucideIcons.chevron_up, size: 18),
              onPressed: widget.totalMatches > 0 ? widget.onPreviousMatch : null,
              tooltip: 'Previous match',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(LucideIcons.chevron_down, size: 18),
              onPressed: widget.totalMatches > 0 ? widget.onNextMatch : null,
              tooltip: 'Next match',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16),
              onPressed: () {
                _controller.clear();
                setState(() {});
                widget.onQueryChanged('');
              },
              tooltip: 'Clear',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            onPressed: widget.onClose,
            tooltip: 'Close search',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
