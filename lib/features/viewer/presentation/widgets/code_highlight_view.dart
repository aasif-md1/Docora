import 'dart:math' as math;

import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:flutter/material.dart';

/// High-performance text and code viewer with numbered gutter,
/// search term highlighting, word wrap toggle, and reading modes.
class CodeHighlightView extends StatefulWidget {
  const CodeHighlightView({
    required this.document,
    required this.fontSize,
    required this.showLineNumbers,
    required this.wrapLines,
    this.searchQuery = '',
    this.currentMatchLine,
    this.readingMode = PdfReadingMode.normal,
    super.key,
  });

  final TextDocument document;
  final double fontSize;
  final bool showLineNumbers;
  final bool wrapLines;
  final String searchQuery;
  final int? currentMatchLine;
  final PdfReadingMode readingMode;

  @override
  State<CodeHighlightView> createState() => _CodeHighlightViewState();
}

class _CodeHighlightViewState extends State<CodeHighlightView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(CodeHighlightView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMatchLine != null &&
        widget.currentMatchLine != oldWidget.currentMatchLine) {
      _scrollToLine(widget.currentMatchLine!);
    }
  }

  void _scrollToLine(int lineIndex) {
    if (!_scrollController.hasClients) return;
    final approxLineHeight = widget.fontSize * 1.5;
    final targetY = lineIndex * approxLineHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    final target = (targetY - viewportHeight / 3).clamp(0.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return const Color(0xFF14141B);
      case PdfReadingMode.sepia:
        return const Color(0xFFFBF0D9);
      case PdfReadingMode.grayscale:
        return Colors.white;
      case PdfReadingMode.normal:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF16161E)
            : const Color(0xFFFAFAFD);
    }
  }

  Color _getGutterColor(BuildContext context) {
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return const Color(0xFF1C1C24);
      case PdfReadingMode.sepia:
        return const Color(0xFFEFE2C6);
      case PdfReadingMode.grayscale:
        return const Color(0xFFECECEC);
      case PdfReadingMode.normal:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F2A)
            : const Color(0xFFF1F0F7);
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return Colors.white70;
      case PdfReadingMode.sepia:
        return const Color(0xFF382D1F);
      case PdfReadingMode.grayscale:
        return Colors.black87;
      case PdfReadingMode.normal:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  Color _getGutterTextColor(BuildContext context) {
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return Colors.white38;
      case PdfReadingMode.sepia:
        return const Color(0xFF8A7760);
      case PdfReadingMode.grayscale:
        return Colors.grey.shade600;
      case PdfReadingMode.normal:
        return Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(160);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.document.lines;
    final lineCount = lines.length;

    final bgColor = _getBackgroundColor(context);
    final gutterColor = _getGutterColor(context);
    final textColor = _getTextColor(context);
    final gutterTextColor = _getGutterTextColor(context);

    // Calculate gutter width based on digit count
    final digits = math.max(lineCount.toString().length, 2);
    final gutterWidth = widget.showLineNumbers ? (digits * 9.5 + 24.0) : 0.0;

    Widget bodyList = ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      itemCount: lineCount,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final lineText = lines[index];
        final isMatchLine = widget.searchQuery.isNotEmpty &&
            lineText.toLowerCase().contains(widget.searchQuery.toLowerCase());
        final isCurrentMatch = widget.currentMatchLine == index;

        return ColoredBox(
          color: isCurrentMatch
              ? Colors.amber.withAlpha(120)
              : (isMatchLine ? Colors.amber.withAlpha(40) : Colors.transparent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line Number Gutter
              if (widget.showLineNumbers)
                Container(
                  width: gutterWidth,
                  padding: const EdgeInsets.only(right: 12),
                  alignment: Alignment.centerRight,
                  color: gutterColor,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.fontSize * 0.85,
                      color: isCurrentMatch ? Colors.amber.shade900 : gutterTextColor,
                      fontWeight: isCurrentMatch ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),

              // Code / Text line
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SelectableText.rich(
                    _buildHighlightedLine(lineText, textColor),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.fontSize,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // If wrap is disabled, wrap in horizontal scrolling viewport
    if (!widget.wrapLines) {
      bodyList = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: math.max(MediaQuery.sizeOf(context).width * 2.5, 1200.0),
          child: bodyList,
        ),
      );
    }

    return ColoredBox(
      color: bgColor,
      child: bodyList,
    );
  }

  TextSpan _buildHighlightedLine(String text, Color defaultColor) {
    if (widget.searchQuery.isEmpty || !text.toLowerCase().contains(widget.searchQuery.toLowerCase())) {
      return TextSpan(text: text, style: TextStyle(color: defaultColor));
    }

    final spans = <TextSpan>[];
    final q = widget.searchQuery.toLowerCase();
    int start = 0;

    final lower = text.toLowerCase();
    while (true) {
      final index = lower.indexOf(q, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: TextStyle(color: defaultColor)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: TextStyle(color: defaultColor)));
      }

      final matchedText = text.substring(index, index + q.length);
      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(
            backgroundColor: Colors.amber.shade300,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + q.length;
    }

    return TextSpan(children: spans);
  }
}
