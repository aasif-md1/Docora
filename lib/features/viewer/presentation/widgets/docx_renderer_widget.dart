import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/viewer/domain/models/docx_models.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a parsed [DocxDocument] inside an authentic paper sheet canvas (similar to PDF/Word layout),
/// featuring standard page margins, paper elevation, page break separation, header ribbon,
/// dynamic font scaling, and search highlighting.
class DocxRendererWidget extends StatelessWidget {
  const DocxRendererWidget({
    required this.document,
    required this.fontScale,
    required this.readingMode,
    required this.searchQuery,
    required this.activeMatchIndex,
    required this.blockKeys,
    this.topPadding = AppSpacing.xl,
    this.bottomPadding = AppSpacing.xl,
    super.key,
  });

  final DocxDocument document;
  final double fontScale;
  final PdfReadingMode readingMode;
  final String searchQuery;
  final int activeMatchIndex;
  final List<GlobalKey> blockKeys;
  final double topPadding;
  final double bottomPadding;

  Color _resolveDefaultTextColor(BuildContext context) {
    switch (readingMode) {
      case PdfReadingMode.dark:
        return Colors.white.withAlpha(235);
      case PdfReadingMode.sepia:
        return const Color(0xFF433422);
      case PdfReadingMode.grayscale:
        return Colors.black;
      case PdfReadingMode.normal:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1E293B);
    }
  }

  Color _resolvePaperColor(BuildContext context) {
    switch (readingMode) {
      case PdfReadingMode.dark:
        return const Color(0xFF1C1C28);
      case PdfReadingMode.sepia:
        return const Color(0xFFFAF3E3);
      case PdfReadingMode.grayscale:
        return Colors.white;
      case PdfReadingMode.normal:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C28)
            : Colors.white;
    }
  }

  void _showLinkConfirmation(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        icon: Icon(
          LucideIcons.external_link,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: const Text('Open External Link?'),
        content: Text(
          url,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          DocoraButton(
            label: 'Open',
            icon: LucideIcons.external_link,
            size: DocoraButtonSize.small,
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paperColor = _resolvePaperColor(context);

    return SelectionArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: topPadding,
              bottom: bottomPadding,
            ),
            children: [
              // Word Document Paper Sheet Container
              Container(
                decoration: BoxDecoration(
                  color: paperColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 90 : 25),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Document Header Ribbon
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.file_text,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Word Document',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          if (document.wordCount > 0)
                            Text(
                              '${document.wordCount} words  •  ~${document.estimatedReadingMinutes} min read',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Document Blocks inside Paper Sheet
                    ...List.generate(document.blocks.length, (index) {
                      final block = document.blocks[index];
                      final key = index < blockKeys.length ? blockKeys[index] : null;

                      return Container(
                        key: key,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: _buildBlock(context, block, index),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, DocxBlock block, int blockIndex) =>
      switch (block) {
        DocxParagraphBlock() => _buildParagraph(context, block),
        DocxTableBlock() => _buildTable(context, block),
        DocxPageBreakBlock() => _buildPageBreak(context),
      };

  Widget _buildParagraph(BuildContext context, DocxParagraphBlock block) {
    final theme = Theme.of(context);
    final defaultColor = _resolveDefaultTextColor(context);

    // Quote style wrapper
    if (block.style == DocxParagraphStyle.quote) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 4,
            ),
          ),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(AppSpacing.radiusSm),
            bottomRight: Radius.circular(AppSpacing.radiusSm),
          ),
        ),
        child: _buildTextContent(context, block, defaultColor),
      );
    }

    // Heading 1 with Word-style primary left accent
    if (block.style == DocxParagraphStyle.heading1) {
      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 10),
        child: _buildTextContent(context, block, defaultColor),
      );
    }

    // List item with bullet or numbering
    if (block.isListItem) {
      final prefix = block.isBullet ? '•  ' : '${block.listIndex}.  ';
      final indent = (block.listLevel * 16.0) + 8.0;

      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prefix,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0 * fontScale,
                color: theme.colorScheme.primary,
              ),
            ),
            Expanded(child: _buildTextContent(context, block, defaultColor)),
          ],
        ),
      );
    }

    return _buildTextContent(context, block, defaultColor);
  }

  Widget _buildTextContent(
    BuildContext context,
    DocxParagraphBlock block,
    Color defaultColor,
  ) {
    // Check if paragraph contains full-width images
    final imageRuns = block.runs.where((r) => r.isImage).toList();
    if (imageRuns.isNotEmpty && block.plainText.trim().isEmpty) {
      return Column(
        children: imageRuns.map((r) => _buildImage(context, r)).toList(),
      );
    }

    final spans = <InlineSpan>[];
    for (final run in block.runs) {
      if (run.isImage) {
        spans.add(WidgetSpan(child: _buildImage(context, run)));
        continue;
      }

      final runStyle = _resolveRunStyle(context, block.style, run, defaultColor);
      final text = run.text;

      if (searchQuery.isNotEmpty &&
          text.toLowerCase().contains(searchQuery.toLowerCase())) {
        spans.addAll(_buildHighlightedSpans(text, runStyle, run.hyperlinkUrl, context));
      } else {
        spans.add(
          TextSpan(
            text: text,
            style: runStyle,
            recognizer: run.isHyperlink
                ? (TapGestureRecognizer()
                  ..onTap = () => _showLinkConfirmation(context, run.hyperlinkUrl!))
                : null,
          ),
        );
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textAlign: block.alignment.toTextAlign(),
    );
  }

  TextStyle _resolveRunStyle(
    BuildContext context,
    DocxParagraphStyle pStyle,
    DocxRun run,
    Color defaultColor,
  ) {
    double baseSize = 14.0;
    FontWeight weight = FontWeight.normal;
    Color color = run.color ?? defaultColor;

    switch (pStyle) {
      case DocxParagraphStyle.title:
        baseSize = 26.0;
        weight = FontWeight.bold;
      case DocxParagraphStyle.subtitle:
        baseSize = 18.0;
        weight = FontWeight.w500;
      case DocxParagraphStyle.heading1:
        baseSize = 21.0;
        weight = FontWeight.bold;
        color = Theme.of(context).colorScheme.primary;
      case DocxParagraphStyle.heading2:
        baseSize = 17.5;
        weight = FontWeight.bold;
      case DocxParagraphStyle.heading3:
        baseSize = 15.5;
        weight = FontWeight.w600;
      case DocxParagraphStyle.heading4:
        baseSize = 14.5;
        weight = FontWeight.w600;
      case DocxParagraphStyle.quote:
        baseSize = 14.0;
        color = defaultColor.withAlpha(200);
      case DocxParagraphStyle.code:
        baseSize = 13.0;
      case DocxParagraphStyle.heading5:
      case DocxParagraphStyle.heading6:
      case DocxParagraphStyle.normal:
        baseSize = 14.0;
    }

    if (run.fontSizePt != null) {
      baseSize = run.fontSizePt!;
    }

    if (run.isBold) weight = FontWeight.bold;
    if (run.isHyperlink) {
      color = Theme.of(context).colorScheme.primary;
    }

    return TextStyle(
      fontSize: baseSize * fontScale,
      fontWeight: weight,
      fontStyle: run.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: run.isHyperlink
          ? TextDecoration.underline
          : (run.isUnderline
              ? TextDecoration.underline
              : (run.isStrike ? TextDecoration.lineThrough : null)),
      decorationColor: color,
      color: color,
      backgroundColor: run.highlightColor,
      fontFamily: pStyle == DocxParagraphStyle.code ? 'monospace' : run.fontFamily,
      fontFamilyFallback: const [
        'Roboto',
        'Noto Sans',
        'Noto Color Emoji',
        'sans-serif',
      ],
      height: 1.45,
    );
  }

  List<InlineSpan> _buildHighlightedSpans(
    String text,
    TextStyle baseStyle,
    String? hyperlinkUrl,
    BuildContext context,
  ) {
    final spans = <InlineSpan>[];
    final query = searchQuery.toLowerCase();
    final lower = text.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final idx = lower.indexOf(query, start);
      if (idx == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: baseStyle,
            recognizer: hyperlinkUrl != null
                ? (TapGestureRecognizer()
                  ..onTap = () => _showLinkConfirmation(context, hyperlinkUrl))
                : null,
          ),
        );
        break;
      }

      if (idx > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, idx),
            style: baseStyle,
            recognizer: hyperlinkUrl != null
                ? (TapGestureRecognizer()
                  ..onTap = () => _showLinkConfirmation(context, hyperlinkUrl))
                : null,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: baseStyle.copyWith(
            backgroundColor: Colors.amber.withAlpha(160),
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          recognizer: hyperlinkUrl != null
              ? (TapGestureRecognizer()
                ..onTap = () => _showLinkConfirmation(context, hyperlinkUrl))
              : null,
        ),
      );

      start = idx + query.length;
    }

    return spans;
  }

  Widget _buildImage(BuildContext context, DocxRun run) {
    final bytes = document.images[run.imageKey];
    if (bytes == null) {
      return const SizedBox.shrink();
    }

    double? width = run.imageWidth;
    final screenWidth = MediaQuery.of(context).size.width - (AppSpacing.lg * 2);
    if (width != null && width > screenWidth) {
      width = screenWidth;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.memory(
            bytes,
            width: width,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, DocxTableBlock table) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Table(
          border: TableBorder.all(
            color: borderColor.withAlpha(100),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: table.rows.map((row) => TableRow(
              decoration: BoxDecoration(
                color: row.isHeader
                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120)
                    : null,
              ),
              children: row.cells.map((cell) => TableCell(
                  child: Container(
                    color: cell.backgroundColor,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cell.paragraphs
                          .map((p) => _buildParagraph(context, p))
                          .toList(),
                    ),
                  ),
                )).toList(),
            )).toList(),
        ),
      ),
    );
  }

  Widget _buildPageBreak(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.file_text,
                  size: 13,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  'Page Break',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ],
      ),
    );
  }
}
