import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Text run inside a presentation slide with typography and styling attributes.
class SlideTextRun {
  const SlideTextRun({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontSize,
    this.color,
    this.fontFamily,
  });

  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final double? fontSize;
  final Color? color;
  final String? fontFamily;
}

/// A paragraph or bullet item within a slide text box.
class SlideParagraph {
  const SlideParagraph({
    required this.runs,
    this.isBullet = false,
    this.level = 0,
    this.alignment = TextAlign.left,
  });

  final List<SlideTextRun> runs;
  final bool isBullet;
  final int level;
  final TextAlign alignment;

  String get plainText => runs.map((r) => r.text).join();
}

/// Normalized bounding box (0.0 to 1.0 relative to slide width and height).
class SlideRect {
  const SlideRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

/// A cell inside a slide table.
class SlideTableCell {
  const SlideTableCell({
    required this.paragraphs,
    this.backgroundColor,
    this.borderColor,
  });

  final List<SlideParagraph> paragraphs;
  final Color? backgroundColor;
  final Color? borderColor;

  String get plainText => paragraphs.map((p) => p.plainText).join('\n');
}

/// A row inside a slide table.
class SlideTableRow {
  const SlideTableRow({
    required this.cells,
    this.heightRatio,
  });

  final List<SlideTableCell> cells;
  final double? heightRatio;
}

/// A structured table on a slide (e.g. multi-column speaker attribution or data grid).
class SlideTable {
  const SlideTable({
    required this.rows,
    this.rect,
    this.columnWidthRatios,
  });

  final List<SlideTableRow> rows;
  final SlideRect? rect;
  final List<double>? columnWidthRatios;

  String get plainText =>
      rows.map((r) => r.cells.map((c) => c.plainText).join('\t')).join('\n');
}

/// A positioned shape or text frame on a slide.
class SlideShape {
  const SlideShape({
    required this.paragraphs,
    this.title = false,
    this.x,
    this.y,
    this.width,
    this.height,
    this.rect,
    this.backgroundColor,
    this.gradientColors,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.isLine = false,
    this.anchorCenter = false,
    this.shapeType,
    this.rotationDegrees,
    this.customPathCommands,
  });

  final List<SlideParagraph> paragraphs;
  final bool title;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final SlideRect? rect;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final bool isLine;
  final bool anchorCenter;
  final String? shapeType;
  final double? rotationDegrees;
  final List<String>? customPathCommands;

  String get plainText => paragraphs.map((p) => p.plainText).join('\n');
}

/// Represents any visual element on a slide in exact Z-order.
abstract class SlideVisualElement {
  SlideRect? get rect;
}

/// An image element in the visual hierarchy.
class SlideImageElement implements SlideVisualElement {
  const SlideImageElement({
    required this.image,
    this.rect,
  });

  final SlideImage image;
  @override
  final SlideRect? rect;
}

/// A shape or text frame element in the visual hierarchy.
class SlideShapeElement implements SlideVisualElement {
  const SlideShapeElement({
    required this.shape,
    this.rect,
  });

  final SlideShape shape;
  @override
  final SlideRect? rect;
}

/// A table element in the visual hierarchy.
class SlideTableElement implements SlideVisualElement {
  const SlideTableElement({
    required this.table,
    this.rect,
  });

  final SlideTable table;
  @override
  final SlideRect? rect;
}

/// An embedded image on a slide.
class SlideImage {
  const SlideImage({
    required this.bytes,
    required this.mimeType,
    this.name,
    this.x,
    this.y,
    this.width,
    this.height,
    this.rect,
    this.rotationDegrees,
  });

  final Uint8List bytes;
  final String mimeType;
  final String? name;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final SlideRect? rect;
  final double? rotationDegrees;
}

/// A complete slide within a presentation deck.
class PresentationSlide {
  const PresentationSlide({
    required this.slideIndex,
    required this.shapes,
    this.images = const [],
    this.tables = const [],
    this.elements = const [],
    this.gradientColors,
    this.backgroundImageBytes,
    this.speakerNotes,
    this.title,
    this.backgroundColor,
  });

  final int slideIndex;
  final List<SlideShape> shapes;
  final List<SlideImage> images;
  final List<SlideTable> tables;
  final List<SlideVisualElement> elements;
  final List<Color>? gradientColors;
  final Uint8List? backgroundImageBytes;
  final String? speakerNotes;
  final String? title;
  final Color? backgroundColor;

  /// Effective title for the slide (explicit or derived from first title shape).
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    for (final shape in shapes) {
      if (shape.title && shape.plainText.trim().isNotEmpty) {
        return shape.plainText.trim();
      }
    }
    for (final shape in shapes) {
      if (shape.plainText.trim().isNotEmpty) {
        final line = shape.plainText.trim().split('\n').first;
        if (line.isNotEmpty) return line;
      }
    }
    return 'Slide ${slideIndex + 1}';
  }

  /// Full plain text across all shapes and tables on the slide for search indexing.
  String get plainText {
    final sb = StringBuffer();
    for (final s in shapes) {
      if (s.plainText.isNotEmpty) sb.writeln(s.plainText);
    }
    for (final t in tables) {
      if (t.plainText.isNotEmpty) sb.writeln(t.plainText);
    }
    return sb.toString().trim();
  }

  bool get hasNotes => speakerNotes != null && speakerNotes!.trim().isNotEmpty;
}

/// Complete in-memory representation of a PowerPoint presentation.
class PresentationDocument {
  const PresentationDocument({
    required this.title,
    required this.filePath,
    required this.fileSizeBytes,
    required this.slides,
    this.slideWidth = 960.0,
    this.slideHeight = 540.0,
    this.isLegacy = false,
  });

  factory PresentationDocument.empty({
    String title = '',
    String filePath = '',
  }) =>
      PresentationDocument(
        title: title,
        filePath: filePath,
        fileSizeBytes: 0,
        slides: const [],
      );

  final String title;
  final String filePath;
  final int fileSizeBytes;
  final List<PresentationSlide> slides;
  final double slideWidth;
  final double slideHeight;
  final bool isLegacy;

  int get slideCount => slides.length;
  double get aspectRatio => slideWidth / (slideHeight > 0 ? slideHeight : 1);
  bool get isWidescreen => (aspectRatio - (16 / 9)).abs() < 0.1;
  int get notesCount => slides.where((s) => s.hasNotes).length;
}
