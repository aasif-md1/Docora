import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Alignment of text inside a DOCX paragraph.
enum DocxAlignment {
  left,
  center,
  right,
  justify;

  TextAlign toTextAlign() {
    switch (this) {
      case DocxAlignment.left:
        return TextAlign.left;
      case DocxAlignment.center:
        return TextAlign.center;
      case DocxAlignment.right:
        return TextAlign.right;
      case DocxAlignment.justify:
        return TextAlign.justify;
    }
  }
}

/// Heading level or paragraph style in a DOCX document.
enum DocxParagraphStyle {
  normal,
  title,
  subtitle,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  quote,
  code;

  bool get isHeading =>
      this == DocxParagraphStyle.heading1 ||
      this == DocxParagraphStyle.heading2 ||
      this == DocxParagraphStyle.heading3 ||
      this == DocxParagraphStyle.heading4 ||
      this == DocxParagraphStyle.heading5 ||
      this == DocxParagraphStyle.heading6;

  int get headingLevel {
    switch (this) {
      case DocxParagraphStyle.heading1:
        return 1;
      case DocxParagraphStyle.heading2:
        return 2;
      case DocxParagraphStyle.heading3:
        return 3;
      case DocxParagraphStyle.heading4:
        return 4;
      case DocxParagraphStyle.heading5:
        return 5;
      case DocxParagraphStyle.heading6:
        return 6;
      default:
        return 0;
    }
  }
}

/// A styled run of text inside a paragraph.
class DocxRun {
  const DocxRun({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrike = false,
    this.color,
    this.highlightColor,
    this.fontSizePt,
    this.fontFamily,
    this.hyperlinkUrl,
    this.imageKey,
    this.imageWidth,
    this.imageHeight,
  });

  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrike;
  final Color? color;
  final Color? highlightColor;
  final double? fontSizePt;
  final String? fontFamily;
  final String? hyperlinkUrl;
  final String? imageKey;
  final double? imageWidth;
  final double? imageHeight;

  bool get isImage => imageKey != null;
  bool get isHyperlink => hyperlinkUrl != null;
}

/// Abstract base class for all top-level document blocks.
sealed class DocxBlock {
  const DocxBlock();
}

/// A paragraph block containing one or more styled text runs.
class DocxParagraphBlock extends DocxBlock {
  const DocxParagraphBlock({
    required this.runs,
    this.style = DocxParagraphStyle.normal,
    this.alignment = DocxAlignment.left,
    this.isListItem = false,
    this.isBullet = false,
    this.listIndex = 1,
    this.listLevel = 0,
    this.headingId,
  });

  final List<DocxRun> runs;
  final DocxParagraphStyle style;
  final DocxAlignment alignment;
  final bool isListItem;
  final bool isBullet;
  final int listIndex;
  final int listLevel;
  final String? headingId;

  String get plainText => runs.map((r) => r.text).join();
}

/// A single cell inside a table row.
class DocxTableCell {
  const DocxTableCell({
    required this.paragraphs,
    this.backgroundColor,
    this.colSpan = 1,
  });

  final List<DocxParagraphBlock> paragraphs;
  final Color? backgroundColor;
  final int colSpan;

  String get plainText =>
      paragraphs.map((p) => p.plainText).join(' ');
}

/// A single row inside a table.
class DocxTableRow {
  const DocxTableRow({
    required this.cells,
    this.isHeader = false,
  });

  final List<DocxTableCell> cells;
  final bool isHeader;
}

/// A table block containing multiple rows and columns.
class DocxTableBlock extends DocxBlock {
  const DocxTableBlock({
    required this.rows,
    this.columnWidths = const [],
  });

  final List<DocxTableRow> rows;
  final List<double> columnWidths;
}

/// A horizontal divider / page break.
class DocxPageBreakBlock extends DocxBlock {
  const DocxPageBreakBlock();
}

/// Table of contents item extracted from headings.
class DocxHeading {
  const DocxHeading({
    required this.id,
    required this.title,
    required this.level,
    required this.blockIndex,
  });

  final String id;
  final String title;
  final int level;
  final int blockIndex;
}

/// Complete parsed in-memory representation of a DOCX document.
class DocxDocument {
  const DocxDocument({
    required this.blocks,
    required this.headings,
    required this.images,
    required this.wordCount,
    required this.characterCount,
    required this.estimatedReadingMinutes,
  });

  factory DocxDocument.empty() => const DocxDocument(
        blocks: [],
        headings: [],
        images: {},
        wordCount: 0,
        characterCount: 0,
        estimatedReadingMinutes: 0,
      );

  final List<DocxBlock> blocks;
  final List<DocxHeading> headings;
  final Map<String, Uint8List> images;
  final int wordCount;
  final int characterCount;
  final int estimatedReadingMinutes;
}
