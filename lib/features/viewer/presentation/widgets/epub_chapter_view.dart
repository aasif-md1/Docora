import 'package:docora/features/viewer/domain/models/epub_models.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// Renders a single EPUB chapter with font size scaling and reading modes.
class EpubChapterView extends StatelessWidget {
  const EpubChapterView({
    required this.chapter,
    required this.fontSize,
    required this.readingMode,
    this.scrollController,
    super.key,
  });

  final EpubChapter chapter;
  final double fontSize;
  final PdfReadingMode readingMode;
  final ScrollController? scrollController;

  ({Color background, Color foreground}) _getReadingColors(BuildContext context) {
    final theme = Theme.of(context);
    switch (readingMode) {
      case PdfReadingMode.normal:
        return (
          background: theme.colorScheme.surface,
          foreground: theme.colorScheme.onSurface,
        );
      case PdfReadingMode.dark:
        return (
          background: const Color(0xFF121212),
          foreground: const Color(0xFFE0E0E0),
        );
      case PdfReadingMode.sepia:
        return (
          background: const Color(0xFFFBF0D9),
          foreground: const Color(0xFF5F4B32),
        );
      case PdfReadingMode.grayscale:
        return (
          background: Colors.grey.shade100,
          foreground: Colors.black87,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getReadingColors(context);

    return ColoredBox(
      color: colors.background,
      child: SelectionArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.title,
                style: TextStyle(
                  fontSize: fontSize * 1.35,
                  fontWeight: FontWeight.bold,
                  color: colors.foreground,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              HtmlWidget(
                chapter.htmlContent,
                textStyle: TextStyle(
                  fontSize: fontSize,
                  color: colors.foreground,
                  height: 1.6,
                ),
                customStylesBuilder: (element) {
                  if (element.localName == 'body') {
                    return {'margin': '0', 'padding': '0'};
                  }
                  if (element.localName == 'p') {
                    return {'margin-bottom': '1em'};
                  }
                  return null;
                },
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
